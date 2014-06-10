Stripe.api_key = ENV['STRIPE_SECRET_KEY']

StripeEvent.setup do
  subscribe 'customer.subscription.created' do |event|
    StripeWebhookHandler.delay.subscription_created(event)
  end

  subscribe 'customer.subscription.updated' do |event|
    StripeWebhookHandler.delay.subscription_updated(event)
  end

  subscribe 'customer.subscription.trial_will_end' do |event|
    StripeWebhookHandler.delay.subscription_trial_will_end(event)
  end

  subscribe 'invoice.payment_succeeded' do |event|
    StripeWebhookHandler.delay.payment_succeeded(event)
  end

  subscribe 'charge.failed' do |event|
    StripeWebhookHandler.delay.charge_failed(event)
  end
end
