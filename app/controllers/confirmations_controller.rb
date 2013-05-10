class ConfirmationsController < ApplicationController
  before_filter :authenticate_user!
  skip_before_filter :check_user_login_status
  layout 'bare'

  def new
  end

  def create
    current_user.validate_confirmation = true
    current_user.username = params[:user][:username]
    current_user.password = params[:user][:password]
    current_user.password_confirmation = params[:user][:password]
    if current_user.save
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
