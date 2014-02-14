# Be sure to restart your server when you modify this file.

require 'uri'

ActionIO::Application.config.session_store :redis_store,
  key: '_aio_session',
  secure: !Rails.env.test?,
  httponly: true,
  domain: '.' + Settings.domain,
  servers: "#{URI.join(ENV['REDISTOGO_URL'], '/0/session_store')} || 'redis://127.0.0.1:6379/0/session_store'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# ActionIO::Application.config.session_store :active_record_store
