class Users::PasswordsController < Devise::PasswordsController
  # Allow accessing edit and update actions while signed-in,
  # so that password reset process from Account Settings works.
  skip_before_filter :require_no_authentication, only: [:edit, :update]
  respond_to :json, only: :create

  def update
    @user = User.reset_password_by_token(params.fetch :user)

    if @user.errors.empty? && @user.active_for_authentication?
      sign_in @user, bypass: :signed_in?
      respond_with @user, location: web_app_url
    else
      respond_with @user
    end
  end
end
