class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super
    if resource.persisted?
      IdentifyMixpanelUserJob.submit_job(user_id: resource.id)
      TrackMixpanelEventJob.submit_job('User Signed Up', resource.id)
    end
  end

  protected
  def after_update_path_for(resource)
    edit_user_registration_path
  end

  # FIXME: override devise #sign_up_params here as devise doesnt seem to able
  # to let us customize this. Furthemore, DeviseParameterSanitizer just doesnt
  # handle authentication_keys/params correctly
  def sign_up_params
    params.require(:user).permit :username, :email, :referrer_code,
      :password, :password_confirmation
  end
end

