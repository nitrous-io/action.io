require 'rubygems'
require 'bundler'
Bundler.require :acceptance
ENV['HOST'] ||= 'https://dev.action.io:5000'
ENV['USERNAME'] ||= 'dqminh'
ENV['PASSWORD'] ||= '123456'
ENV['TEST_BOX_ID'] ||= '174'
ENV['MAX_PROVISION_TIME'] ||= '90'
require 'pry'
require 'capybara/rspec'
require_relative './support'

RSpec.configure do |config|
  config.include Support
  config.include Capybara::DSL
  config.include Capybara::RSpecMatchers
  Capybara.default_wait_time = 10

  Capybara.register_driver :selenium do |app|
    Capybara::Selenium::Driver.new(app, browser: :chrome)
  end

  Capybara.default_driver = :selenium
  Capybara.app_host = ENV['HOST']
end
