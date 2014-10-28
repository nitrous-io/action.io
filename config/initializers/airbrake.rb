Airbrake.configure do |config|
  config.api_key = ENV['AIRBRAKE_API_KEY']

  # https://github.com/airbrake/airbrake/issues/279
  # hide all ENV variables from Airbrake
  ENV.keys.each {|k| config.rake_environment_filters << k }
end if defined? Airbrake
