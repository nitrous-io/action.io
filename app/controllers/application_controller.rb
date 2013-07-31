class ApplicationController < ActionController::Base
  before_filter :check_user_login_status
  protect_from_forgery
  ensure_security_headers
  responders :json

  BONUS_PATH = "/app#/n2o/bonus".freeze

  def check_user_login_status
    if current_user && !current_user.able_to_login?
      redirect_to new_confirmation_path
    end
  end

  protected
  def authorize_user!
    unless current_user.present? && current_user.admin?
      render :text => "Forbidden", :status => 403
    end
  end

  def oauth_token_present?
    Doorkeeper::OAuth::Token.from_request(request, *Doorkeeper.configuration.access_token_methods).present?
  end

  def no_cache
    expires_now
  end
end
