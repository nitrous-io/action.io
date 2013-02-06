class InvitesController < ApplicationController
  before_filter :authenticate_user!, only: [:create, :index]
  layout 'dashboard'

  def index
    @invites = current_user.owned_invites.order('created_at DESC').
      paginate(page: params[:page] || 1, per_page: 20)
  end

  def request_invite
    redirect_url = params[:invite].delete(:redirect_url) || root_path

    if (dupe_invite = Invite.find_by_email(params[:invite][:email])).present?
      @referral_code = dupe_invite.referral_code
    else
      @invite = Invite.new.tap do |i|
        i.email = params[:invite][:email]
        i.referrer_code = params[:invite][:referrer_code]
        i.ip = request.remote_ip
        i.save
      end

      if @invite.valid?
        Notifier.delay.invite_confirmation(@invite.id)
        Delayed::Job.enqueue(GeocodeInviteJob.new(@invite.id))
        TrackMixpanelEventJob.submit_job('Invite Requested')

        if ENV['AUTO_INVITE'] == 'true'
          @invite.activate!
          Notifier.delay.send_invite(@invite.id)
        end
      end
    end

    respond_to do |format|
      format.html do
        flash[:notice] = if @invite.blank?
          "Looks like you've already requested for an invite. Hang tight, we'll be in touch soon!"
        else
          if @invite.valid?
            "Thank you for your interest. We'll be in touch soon!"
          else
            "Looks like you entered an invalid email address, please try again."
          end
        end

        redirect_to redirect_url
      end

      format.js { render :request_invite }
    end
  end

  def create
    user_invitation = UserInvitation.new current_user
    @invite = user_invitation.invite params[:invite][:email]
    if @invite == UserInvitation::NO_INVITE_LEFT
      flash[:notice] = "Looks like you don't have any invites left"
    else
      if @invite.persisted?
        flash[:notice] = "Invite has been sent to #{@invite.email}"
        TrackMixpanelEventJob.submit_job('Invite Sent', current_user.id)
        IncrementMixpanelPropertyJob.submit_job(current_user.id, :invites_sent, 1)
      else
        flash[:notice] = "Looks like you entered an invalid invite, please try again"
      end
    end
    redirect_to invites_path
  end
end
