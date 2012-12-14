require 'rubygems'
require 'spork'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

Spork.prefork do
  ENV['RACK_ENV'] ||= ENV["RAILS_ENV"] ||= 'test'

  require 'rails/application'
  Spork.trap_method(Rails::Application::RoutesReloader, :reload!)

  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
  require 'rspec/autorun'
  require 'shoulda/matchers/integrations/rspec'
  require 'capybara/rspec'
  require 'database_cleaner'
  require 'webmock/rspec'

  RSpec.configure do |config|
    # ## Mock Framework
    #
    # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
    #
    # config.mock_with :mocha
    # config.mock_with :flexmock
    # config.mock_with :rr

    # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
    config.fixture_path = "#{::Rails.root}/spec/fixtures"

    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, remove the following line or assign false
    # instead of true.
    config.use_transactional_fixtures = true

    # If true, the base class of anonymous controllers will be inferred
    # automatically. This will be the default behavior in future versions of
    # rspec-rails.
    config.infer_base_class_for_anonymous_controllers = false

    config.before :suite do
      DatabaseCleaner.strategy = :truncation
      DatabaseCleaner.clean
    end

    config.before :each do
      DatabaseCleaner.clean
      WebMock.disable_net_connect!
    end

    Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| load f }

    config.include Devise::TestHelpers, type: :controller
    config.include FactoryGirl::Syntax::Methods
    config.include RequestSpecHelpers, type: :request
    config.include ControllerSpecHelpers, type: :controller
  end
end

Spork.each_run do
  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.

  FactoryGirl.reload
  I18n.backend.reload!
end

