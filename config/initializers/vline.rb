require 'vline'

Vline.setup do |config|

  config.service_id = 'nitrousio'
  config.provider_id = 'nitrousio'
  config.client_id = ENV['VLINE_CLIENT_ID']

  config.client_secret = ENV['VLINE_CLIENT_SECRET']
  config.provider_secret = ENV['VLINE_PROVIDER_SECRET']
end
