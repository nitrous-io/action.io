class ConfirmationsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :pass_valid_user
  skip_before_filter :check_user_login_status
  layout 'bare'

  def new
    username = current_user.authentications.
      where("username != '' OR username IS NOT NULL").
      pluck(:username).last
    current_user.username = username
  end

  def create
    if current_user.reset_username_and_password params[:user]
      # due to password change, we bypass warden and just refresh the session
      # credentials
      # http://rubydoc.info/github/plataformatec/devise/master/Devise/Controllers/Helpers:sign_in
      sign_in current_user, bypass: true
      if cookies[:hack].present?
        redirect_to cookies.delete(:hack)
      else
        redirect_to web_app_path
      end
    else
      render :new
    end
  end

  def destroy
    current_user.destroy
    sign_out_and_redirect :user
  end

  protected
  def pass_valid_user
    if current_user && current_user.able_to_login?
      redirect_to web_app_path
      return
    end
  end
end
