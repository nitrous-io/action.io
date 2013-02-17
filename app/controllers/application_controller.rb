class ApplicationController < ActionController::Base
  protect_from_forgery
  responders :json

  helper_method :backend_disabled?

  def backend_disabled?
    ENV['DISABLE_BACKEND'] == 'true' && !current_user.admin?
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
end
