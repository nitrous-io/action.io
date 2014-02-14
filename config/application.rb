require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

require 'uri'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module ActionIO
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/app/validators)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation, :key, :keypair, :private_key, :public_key]

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    config.active_record.whitelist_attributes = true

    # Enable the asset pipeline
    #config.assets.initialize_on_precompile = false
    config.assets.enabled = true
    config.assets.precompile += %w(aio.js pages/boxes_terminal_page.js pages/jobs_page.js pages/pricing_page.js bootstrap3/application.css)

    config.action_dispatch.x_sendfile_header = nil

    config.app_generators.stylesheet_engine :sass
    config.sass.preferred_syntax = :sass if config.respond_to? :sass

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
    config.force_ssl = true

    config.settings = ActiveSupport::OrderedOptions.new

    config.settings.domain = ENV['RAILS_DOMAIN']
    config.settings.host = ENV['RAILS_HOST']
    config.settings.host_full = ENV['RAILS_HOST_FULL']
    config.action_controller.asset_host = ENV['ASSET_HOST']

    config.settings.github_id = ENV['GITHUB_ID']
    config.settings.github_secret = ENV['GITHUB_SECRET']

    config.settings.google_id = ENV['GOOGLE_ID']
    config.settings.google_secret = ENV['GOOGLE_SECRET']

    config.settings.linkedin_id = ENV['LINKEDIN_ID']
    config.settings.linkedin_secret = ENV['LINKEDIN_SECRET']

    config.settings.twitter_id = ENV['TWITTER_ID']
    config.settings.twitter_secret = ENV['TWITTER_SECRET']

    config.settings.facebook_id = ENV['FACEBOOK_ID']
    config.settings.facebook_secret = ENV['FACEBOOK_SECRET']

    config.settings.mailchimp_key = ENV['MAILCHIMP_API_KEY']
    config.settings.mailchimp_monthly_newsletter_list_id = ENV['MAILCHIMP_MONTHLY_NEWSLETTER_LIST_ID']
    config.settings.mailchimp_product_announcements_list_id = ENV['MAILCHIMP_PRODUCT_ANNOUNCEMENTS_LIST_ID']
    config.settings.mailchimp_webhook_key = ENV['MAILCHIMP_WEBHOOK_KEY']

    config.settings.papertrail_webhook_key = ENV['PAPERTRAIL_WEBHOOK_KEY']
    config.settings.mixpanel_webhook_key = ENV['MIXPANEL_WEBHOOK_KEY']
    config.settings.wufoo_webhook_key = ENV['WUFOO_WEBHOOK_KEY']

    config.settings.stats_api_key = ENV['STATS_API_KEY']

    config.settings.aes_key = ENV['AES_KEY']

    config.font_assets.origin = ENV['CORS_ALLOWED_ORIGIN']

    config.settings.admin_username = ENV['ADMIN_USERNAME']
    config.settings.admin_password = ENV['ADMIN_PASSWORD']

    config.settings.idle_box_grace_period = ENV['IDLE_BOX_GRACE_PERIOD']
    config.settings.box_termination_grace_period_in_days = ENV['BOX_TERMINATION_GRACE_PERIOD_IN_DAYS']
    config.settings.shover_server_uri = ENV['SHOVER_SERVER_URI']

    config.settings.session_store_servers = "#{URI.join(ENV['REDISTOGO_URL'], '/0/session_store').to_s}"

    config.settings.split_alternatives_config = File.join(Rails.root, 'config', 'split_alternatives.yml')

    config.to_prepare do
      Devise::SessionsController.layout "bare"
      Devise::RegistrationsController.layout proc{ |controller| user_signed_in? ? "dashboard" : "bare" }
      Devise::ConfirmationsController.layout "bare"
      Devise::UnlocksController.layout "bare"
      Devise::PasswordsController.layout "bare"
    end

    config.middleware.insert_before(Rack::Runtime, Rack::Rewrite) do
      r301 %r{/ref=([-\w]+)}, '/?ref=$1'
    end
    config.middleware.use Rack::Attack

    ActiveSupport.escape_html_entities_in_json = true
    ActionDispatch::ParamsParser::DEFAULT_PARSERS.delete Mime::XML # we don't need xml params. disable to improve security
  end
end

Settings = ActionIO::Application.config.settings
