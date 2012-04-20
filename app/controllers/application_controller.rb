class ApplicationController < ActionController::Base
  protect_from_forgery
  responders :json
  after_filter :delete_tty_keys_cookie, unless: -> { user_signed_in? }
  before_filter :force_ssl

  private
  def delete_tty_keys_cookie
    cookies.delete :_aio_tty_keys, domain: ".#{Settings.domain}"
  end

  # remove me later when tty.js is https-protected
  def force_ssl
    if !request.ssl? && !Rails.env.test?
      redirect_options = { protocol: 'https://', status: :moved_permanently }
      redirect_options.merge!(host: host) if host
      redirect_options.merge!(params: request.query_parameters)
      redirect_to redirect_options
    end
  end
end
