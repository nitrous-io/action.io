Konacha.configure do |config|
  require 'capybara/webkit'
  config.spec_dir = 'spec/javascripts'
  config.driver = :webkit
  config.stylesheets = %w(application)
end if defined? Konacha
