# Be sure to restart your server when you modify this file.

ActionIO::Application.config.session_store :redis_store,
  key: '_aio_session',
  secure: !Rails.env.test?,
  httponly: true,
  domain: '.' + Settings.domain,
  servers: ENV['REDISTOGO_URL']

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# ActionIO::Application.config.session_store :active_record_store
