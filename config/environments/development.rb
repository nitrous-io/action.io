ActionIO::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Raise exception on mass assignment protection for Active Record models.
  config.active_record.mass_assignment_sanitizer = :strict

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = false

  config.action_controller.default_url_options = config.action_mailer.default_url_options = {
    host:     config.settings.host,
    port:     5000,
    protocol: 'https'
  }

  # localhost:1025 is where the mailcatcher gem listens to email
  # http://mailcatcher.me
  config.action_mailer.smtp_settings = { host: "localhost", port: 1025 }
  # Using sendgrid for development
  # Setup an account in Sendgrid or whatever email provider you like
  # and fill in the credentials in .env
  # config.action_mailer.delivery_method = :smtp
  # ActionMailer::Base.smtp_settings = {
  #   user_name: ENV['ACTIONMAILER_USERNAME'],
  #   password: ENV['ACTIONMAILER_PASSWORD'],
  #   domain: config.settings.host,
  #   address: ENV['ACTIONMAILER_ADDRESS'],
  #   port: ENV['ACTIONMAILER_PORT'],
  #   authentication: :plain,
  #   enable_starttls_auto: true
  # }

  config.ember.variant = :development

  config.qunit.tests_path = File.join('spec', 'qunit')
  config.qunit.javascripts_path = '.'
  config.qunit.stylesheets_path = '.'
end
