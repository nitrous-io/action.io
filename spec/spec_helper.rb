prefork = -> do
  ENV['RACK_ENV'] ||= ENV["RAILS_ENV"] ||= 'test'

  require 'rails/application'

  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'
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

      # Clear all environment variables related to nitrous.io here
    end

    config.before :each do
      DatabaseCleaner.clean
      WebMock.disable_net_connect!
    end
  end
end

each_run = -> do
  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.

  FactoryGirl.reload
  I18n.backend.reload!

  Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| load f }

  RSpec.configure do |config|
    config.include Devise::TestHelpers, type: :controller
    config.include FactoryGirl::Syntax::Methods
    config.include RequestSpecHelpers, type: :request
    config.include ControllerSpecHelpers, type: :controller
  end
end

prefork.call
$each_run = each_run
class << Zeus.plan
  def after_fork_with_test
    after_fork_without_test
    $each_run.call
  end
  alias_method_chain :after_fork, :test
end
