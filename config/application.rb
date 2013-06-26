require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module ActionIO
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    #config.autoload_paths += %W(#{config.root}/app/lib/rack)

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
    config.assets.precompile += %w( aio.js pages/boxes_terminal_page.js pages/jobs_page.js pages/pricing_page.js)
    config.assets.compress = true

    config.action_dispatch.x_sendfile_header = nil

    config.assets.js_compressor = :closure
    config.assets.css_compressor = :yui

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

    config.settings.aes_key = ENV['AES_KEY']

    config.font_assets.origin = ENV['CORS_ALLOWED_ORIGIN']

    config.to_prepare do
      Devise::SessionsController.layout "bare"
      Devise::RegistrationsController.layout proc{ |controller| user_signed_in? ? "dashboard" : "bare" }
      Devise::ConfirmationsController.layout "bare"
      Devise::UnlocksController.layout "bare"
      Devise::PasswordsController.layout "bare"
    end

    config.middleware.insert_before(Rack::Lock, Rack::Rewrite) do
      r301 %r{/ref=([-\w]+)}, '/?ref=$1'
    end

    ActiveSupport.escape_html_entities_in_json = true
    ActionDispatch::ParamsParser::DEFAULT_PARSERS.delete Mime::XML # we don't need xml params. disable to improve security
  end
end

Settings = ActionIO::Application.config.settings
