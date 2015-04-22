class AuthenticationsController < ApplicationController
  before_filter :find_valid_authentication
  layout 'bare'

  def edit
  end

  def update
    if @user.valid_password? params[:user][:password]
      @authentication.update_attribute :confirmed, true
      sign_in @user
      redirect_to BONUS_PATH
    else
      @user.errors.add :password, 'does not match'
      render :edit
    end
  end

  def destroy
    @authentication.destroy
    redirect_to web_app_path
  end

  protected
  def find_valid_authentication
    authentication = Authentication.find(params[:id])
    if authentication.token != params[:token]
      raise "Invalid Authentication Token"
    elsif authentication.confirmed?
      redirect_to BONUS_PATH
    else
      @authentication = authentication
      @token = params[:token]
      @user = @authentication.user
    end
  end
end
