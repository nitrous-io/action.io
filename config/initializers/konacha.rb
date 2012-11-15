Konacha.configure do |config|
  require 'capybara/webkit'
  # assume that we are going to run test with port 3500
  Capybara.app_host = "http://dev.action.io:3500"
  Capybara.server_port = 3500

  config.spec_dir = 'spec/javascripts'
  config.driver = :webkit
  config.stylesheets = %w(application)
end if defined? Konacha
