Koudoku.setup do |config|
  config.webhooks_api_key = "35338f55-748b-42ca-b956-e342c2821e9b"
  config.subscriptions_owned_by = :user
  config.stripe_publishable_key = ENV['STRIPE_PUBLISHABLE_KEY']
  config.stripe_secret_key = ENV['STRIPE_SECRET_KEY']
  # config.free_trial_length = 30
end
