web: bundle exec unicorn -E $RACK_ENV -c ./config/unicorn.rb
worker: bundle exec rake jobs:work

