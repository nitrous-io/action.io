class InvitesController < ApplicationController
  before_filter :authenticate_user!, :only => [:index]
  before_filter :authorize_user!, :only => [:index, :send_invite]

  layout 'dashboard'

  def index
    @filter = params[:filter]

    if params.has_key?(:q) && params[:q].length > 3
      @invites = Invite.where("city = ?", params[:q]).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
    else
      @invites = if @filter.blank? || @filter == 'pending'
        Invite.pending
      elsif @filter == 'activated'
        Invite.activated
      elsif @filter == 'accepted'
        Invite.accepted
      end.order('created_at DESC').paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
    end
  end

  def send_invite
    @invite = Invite.find params[:id]
    @invite.activate! if @invite.state == 'pending' && @invite.state != 'accepted'
    Notifier.delay.send_invite(@invite.id)
    flash[:notice] = 'Your invite was sent.'
    redirect_to invites_url
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
