class InvitesController < ApplicationController
  def request_invite
    redirect_url = params[:invite].delete(:redirect_url) || root_path

    if Invite.find_by_email(params[:invite][:email]).present?
      flash[:notice] = "Looks like you've already requested for an invite. Hang tight, we'll be in touch soon!"
    else
      @invite = Invite.create(:email => params[:invite][:email])
      if @invite.valid?
        flash[:notice] = "Thank you for your interest. We'll be in touch soon!"
        Notifier.delay.invite_confirmation(@invite.email)
      else
        flash[:notice] = "Looks like you entered an invalid email address, please try again."
      end
    end

    redirect_to redirect_url
  end
end
