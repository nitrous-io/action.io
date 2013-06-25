class AuthenticationsController < ApplicationController
  before_filter :find_valid_authentication
  layout 'bare'

  def edit
  end

  def update
    if @user.valid_password? params[:user][:password]
      @authentication.update_attribute :confirmed, true
      sign_in @user
      redirect_to web_app_url
    else
      @user.errors.add :password, 'does not match'
      render :edit
    end
  end

  protected
  def find_valid_authentication
    authentication = Authentication.find(params[:id])
    if authentication.token != params[:token]
      raise "Invalid Authentication Token"
    elsif authentication.confirmed?
      redirect_to web_app_url
    else
      @authentication = authentication
      @token = params[:token]
      @user = @authentication.user
    end
  end
end
