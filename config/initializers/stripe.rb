Stripe.api_key = ENV['STRIPE_SECRET_KEY']

StripeEvent.setup do
  subscribe 'customer.subscription.created' do |event|
    customer_id = event.data.customer
    plan_id = event.data.plan.id

    Subscription.delay.create_from_stripe customer_id, plan_id
  end
end
