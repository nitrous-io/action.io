class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super
    if resource.persisted?
      # auto-request an invite
      invite = resource.request_invite(request.remote_ip)
      # This will be replaced with the welcome email once we remove
      # this invite business
      InviteMailer.delay.send_confirmation(invite.id)
      IdentifyMixpanelUserJob.submit_job(user_id: resource.id)
      TrackMixpanelEventJob.submit_job('User Signed Up', resource.id)
    end
  end

  protected
  def after_update_path_for(resource)
    edit_user_registration_path
  end
end

