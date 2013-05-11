class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super
    if resource.persisted?
      # auto-request an invite
      invite = resource.request_invite(request.remote_ip)
      # If the invite has been activated (for e.g. by an admin
      # or a user inviting another user), then accept the invite
      if invite.activated?
        invite.accept!
        UserMailer.delay.welcome(resource.email)
      else
        # This will be replaced with the welcome email once we remove
        # this invite business
        InviteMailer.delay.send_confirmation(invite.id)
      end

      IdentifyMixpanelUserJob.submit_job(user_id: resource.id)
      TrackMixpanelEventJob.submit_job('User Signed Up', resource.id)
    end
  end

  protected
  def after_update_path_for(resource)
    edit_user_registration_path
  end
end

