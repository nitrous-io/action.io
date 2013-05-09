class ConfirmationsController < ApplicationController
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
      redirect_to root_path
    else
      render :new
    end
  end
end
