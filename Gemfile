source 'https://rubygems.org'
ruby '2.1.1'

gem 'rails',                      '4.0.3'
gem 'rack',                       '~> 1.5.2'
gem 'protected_attributes',       '~> 1.0.5'
gem 'redis-rails',                '~> 4.0.0'

gem 'pg',                         '~> 0.17.1'
gem 'json',                       '~> 1.8.1'

gem 'responders',                 '~> 1.0.0'

gem 'haml',                       '~> 4.0.4'
gem 'haml-rails',                 '~> 0.5.2'
gem 'sass',                       '~> 3.2.9'
gem 'jquery-rails',               '~> 2.1.4' # jquery 1.8

gem 'devise',                     '~> 3.0.1'
gem 'omniauth-github',            '~> 1.1.0'
gem 'omniauth-google-oauth2',     '~> 0.1.17'
gem 'omniauth-linkedin',          '~> 0.1.0'
gem 'omniauth-twitter',           '~> 1.0.0'
gem 'omniauth-facebook',          '~> 1.4.1'
gem 'simple_form',                '~> 3.0.1'
gem 'maruku',                     '~> 0.6.1'

gem 'active_model_serializers',   '~> 0.7.0'
gem 'state_machine',              '~> 1.2.0'
gem 'sshkey',                     '~> 1.6.1'
gem 'httparty',                   '~> 0.10.2'
gem 'twitter',                    '~> 5.3.0'
gem 'gibbon',                     '~> 0.4.6'

gem 'pusher',                     '~> 0.11.3'

gem 'newrelic_rpm'

gem 'net-ssh',                    '~> 2.6.7'
gem 'delayed_job',                '~> 4.0.0'
gem 'delayed_job_active_record',  '~> 4.0.0'
gem 'rack-rewrite',               '~> 1.3.3'

gem 'ember-rails',                '0.11.1'
gem 'ember-source',               '0.0.8'
gem 'ember-data-source',          '0.0.5'
gem 'handlebars-source',          '1.0.0.rc3'
gem 'hamlbars',                   '~> 1.1.0'
gem 'barber',                     '0.4.1'

gem 'octokit',                    '~> 2.6.2'
gem 'doorkeeper',                 '~> 1.0.0.rc1'
gem 'switch_user',                '~> 0.9.2'
gem 'mixpanel',                   '~> 4.0.3', require: 'mixpanel'
gem 'stripe',                     '~> 1.8.5'
gem 'stripe_event',               '~> 0.6.1'

gem 'firebase_token_generator',   '~> 1.0.1'
gem 'zeroclipboard-rails',        '~> 0.0.4'
gem 'secure_headers',             '~> 1.0.0'

gem 'linkedin',                   '~> 0.4.2'
gem 'rack-attack',                '~> 2.2.1'

gem 'sass-rails',                 '~> 4.0.1'
gem 'bootstrap-sass',             '~> 2.3.1.0'
gem 'coffee-rails',               '~> 4.0.1'
gem 'yui-compressor',             '~> 0.11.0'
gem 'closure-compiler',           '~> 1.1.8'
gem 'execjs',                     '~> 1.4.0'
gem 'font-awesome-rails',         '~> 4.0.3.1'

gem 'with_advisory_lock',         '~> 0.0.10'
gem 'font_assets',                github: 'nitrous-io/font_assets'
gem 'split',                      '~> 0.7.0', require: 'split/dashboard'

gem 'sanitize',                   '~> 2.1.0'
gem 'dogapi',                     '~> 1.9.2'

group :production do
  gem 'unicorn',                  '~> 4.6.2'
  gem 'airbrake',                 '>= 3.1.12'
  gem 'memcachier',               '~> 0.0.2'
  gem 'dalli',                    '~> 2.6.4'
  gem 'skylight'
end

group :development do
  gem 'thin',                     '~> 1.6.1'
  gem 'foreman',                  '~> 0.60.2' # don't update
  gem 'pry-rails',                '~> 0.3.2'
  #gem 'ruby-debug19', require: 'ruby-debug'
end

group :development, :test do
  gem 'zeus',                     '~> 0.13.3'
  gem 'rspec-rails',              '= 3.0.0.beta1'
  gem 'rspec-its',                '~> 1.0.0.pre'
  gem 'fivemat',                  '~> 1.2.1'
  gem 'mochajs_rails',            github: 'nitrous-io/mochajs_rails'
  gem 'fakefs',                   '~> 0.5.0', require: 'fakefs/safe'
end

group :test do
  gem 'database_cleaner',         '~> 1.2.0'
  gem 'capybara',                 '~> 2.2.0'
  gem 'capybara-webkit',          '~> 1.1.0'
  gem 'poltergeist',              '~> 1.5.0'
  gem 'factory_girl_rails',       '~> 4.3.0'
  gem 'shoulda-matchers',         '~> 2.4.0'
  gem 'timecop',                  '~> 0.7.0'
  gem 'webmock',                  '~> 1.9.3'
  gem 'email_spec',               '~> 1.5.0'
end
