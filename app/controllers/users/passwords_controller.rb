class Users::PasswordsController < Devise::PasswordsController
  skip_before_filter :require_no_authentication, only: [:edit, :update]
  respond_to :json, only: :create

  protected
  def after_resetting_password_path_for(resource)
    web_app_url
  end
end
