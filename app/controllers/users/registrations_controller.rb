class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super
    if resource.persisted?
      resource.mark_collaboration_invites_as_accepted!

      UserMailer.delay.welcome(resource.email)
      IdentifyMixpanelUserJob.submit_job(user_id: resource.id)
      TrackMixpanelEventJob.submit_job('User Signed Up', resource.id)
    end
  end

  protected
  def after_update_path_for(resource)
    edit_user_registration_path
  end
end

