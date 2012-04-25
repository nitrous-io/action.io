source :rubygems
source "https://aio:umMkXQB6z2rmAQcvCgovsYAiXJjAvRjG@action-gem-server.herokuapp.com/"

gem 'rails', '3.2.3'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'pg',                   '~> 0.13.2'

gem "hiredis",              '~> 0.4.5'
gem "redis",                '~> 2.2.2', require: ['redis/connection/hiredis', 'redis']

gem 'responders',           '~> 0.9.1'

gem 'haml',                 '~> 3.1.4'
gem 'haml-rails',           '~> 0.3.4'
gem 'jquery-rails',         '~> 2.0.2'
gem 'coffee-filter',        '~> 0.1.1'

gem 'devise',               '~> 2.0.4'
gem 'omniauth-github',      '~> 1.0.1'
gem 'simple_form',          '~> 2.0.1'

gem 'resque',               '~> 1.20.0', require: 'resque/server'

gem 'state_machine',        '~> 1.1.2'
gem 'sshkey',               '~> 1.3.0'
gem 'httparty',             '~> 0.8.2'

gem 'pusher',               '~> 0.9.2'
gem 'newrelic_rpm',         '~> 3.3.4.1'

gem 'action_boxer',         '0.0.12'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',         '~> 3.2.5'
  gem "bootstrap-sass",     '~> 2.0.2'
  gem 'coffee-rails',       '~> 3.2.2'
  gem 'uglifier',           '>= 1.2.4'
  gem 'haml_coffee_assets', '~> 0.8.5'
  gem 'execjs',             '~> 1.3.0'
end

group :production do
  gem 'unicorn',            '~> 4.3.0'
end

group :development do
  gem 'thin',               '~> 1.3.1'
  gem 'foreman',            '~> 0.43.0'
  gem 'heroku',             '~> 2.24.1'
end

group :development, :test do
  gem 'rspec-rails',        '~> 2.9.0'
  gem 'jasminerice',        '~> 0.0.8'
end

group :test do
  gem 'database_cleaner',   '~> 0.7.2'
  gem 'capybara',           '~> 1.1.2'
  gem 'factory_girl_rails', '~> 3.1.0'
  gem 'faker',              '~> 1.0.1'
  gem 'shoulda-matchers',   '~> 1.1.0'
  gem 'spork-rails',        '~> 3.2.0'
  gem 'timecop',            '~> 0.3.5'
  gem 'webmock',            '~> 1.8.6'
end

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

