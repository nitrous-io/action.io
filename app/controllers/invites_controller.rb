class InvitesController < ApplicationController
  before_filter :authenticate_user!, :only => [:index]
  before_filter :authorize_user!, :only => [:index]

  def index
    @filter = params[:filter]
    @invites = if params[:filter].blank? || params[:filter] == 'pending'
      Invite.pending
    elsif params[:filter] == 'activated'
      Invite.activated
    elsif params[:filter] == 'accepted'
      Invite.accepted
    end
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
end
