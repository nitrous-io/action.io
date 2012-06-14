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

    if Invite.find_by_email(params[:invite][:email]).present?
      flash[:notice] = "Looks like you've already requested for an invite. Hang tight, we'll be in touch soon!"
    else
      @invite = Invite.new.tap do |i|
        i.email = params[:invite][:email]
        i.ip = request.remote_ip
        i.save
      end

      if @invite.valid?
        flash[:notice] = "Thank you for your interest. We'll be in touch soon!"
        Notifier.delay.invite_confirmation(@invite.email)
        Delayed::Job.enqueue(GeocodeInviteJob.new(@invite.id))
      else
        flash[:notice] = "Looks like you entered an invalid email address, please try again."
      end
    end

    redirect_to redirect_url
  end
end
