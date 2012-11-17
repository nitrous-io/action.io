Konacha.configure do |config|
  require 'capybara/poltergeist'
  # if ASSET_HOST is not dev.action.io:3500 somehow, assets cant be loaded
  # in that case, we enforced dev.action.io:3500
  Capybara.app_host = "http://dev.action.io:3500"
  Capybara.server_port = 3500

  config.spec_dir = 'spec/javascripts'
  config.driver = :poltergeist
  config.stylesheets = %w(application)
end if defined? Konacha
