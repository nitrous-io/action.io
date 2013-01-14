class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super
    if resource.persisted?
      METRICS.increment "users.signed_up"
      UserMailer.delay.welcome resource.email
    end
  end

  protected
  def after_update_path_for(resource)
    edit_user_registration_path
  end
end

