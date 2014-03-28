Stripe.api_key = ENV['STRIPE_SECRET_KEY']

StripeEvent.setup do
  subscribe 'customer.subscription.created' do |event|
    StripeWebhookHandler.delay.subscription_created(event)
  end

  subscribe 'customer.subscription.updated' do |event|
    StripeWebhookHandler.delay.subscription_updated(event)
  end

  subscribe 'customer.subscription.deleted' do |event|
    StripeWebhookHandler.delay.subscription_deleted(event)
  end

  subscribe 'invoice.created' do |event|
    StripeWebhookHandler.delay.invoice_created(event)
  end

  subscribe 'invoice.payment_succeeded' do |event|
    StripeWebhookHandler.delay.payment_succeeded(event)
  end

  subscribe 'charge.succeeded' do |event|
    StripeWebhookHandler.delay.charge_succeeded(event)
  end

  subscribe 'charge.failed' do |event|
    StripeWebhookHandler.delay.charge_failed(event)
  end

  subscribe 'charge.refunded' do |event|
    StripeWebhookHandler.delay.charge_refunded(event)
  end
end
