class ConfirmationsController < ApplicationController
  before_filter :authenticate_user!
  skip_before_filter :check_user_login_status
  layout 'bare'

  def new
  end

  def create
    if current_user.reset_username_and_password params[:user]
      # due to password change, we bypass warden and just refresh the session
      # credentials
      # http://rubydoc.info/github/plataformatec/devise/master/Devise/Controllers/Helpers:sign_in
      sign_in current_user, bypass: true
      redirect_to web_app_path
    else
      render :new
    end
  end
end
