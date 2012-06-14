class ApplicationController < ActionController::Base
  protect_from_forgery
  responders :json
  after_filter :delete_tty_keys_cookie, unless: -> { user_signed_in? }

  private
  def delete_tty_keys_cookie
    cookies.delete :_aio_tty_keys, domain: ".#{Settings.domain}"
  end
end
