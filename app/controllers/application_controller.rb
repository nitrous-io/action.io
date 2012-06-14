class ApplicationController < ActionController::Base
  protect_from_forgery
  responders :json
  after_filter :delete_tty_keys_cookie, unless: -> { user_signed_in? }

  protected
  def authorize_user!
    unless current_user.present? && current_user.admin?
      render :text => "Forbidden", :status => 403
    end
  end

  private
  def delete_tty_keys_cookie
    cookies.delete :_aio_tty_keys, domain: ".#{Settings.domain}"
  end
end
