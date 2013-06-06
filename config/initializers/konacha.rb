Konacha.configure do |config|
  require 'capybara/poltergeist'
  # if ASSET_HOST is not www.n2odev.com:3500 somehow, assets cant be loaded
  Capybara.app_host = "http://www.n2odev.com:3500"
  Capybara.server_port = 3500

  config.spec_dir = 'spec/javascripts'
  config.driver = :poltergeist
  config.stylesheets = %w(application)
end if defined? Konacha
