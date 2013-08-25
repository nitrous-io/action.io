Stripe.api_key = ENV['STRIPE_SECRET_KEY']

StripeEvent.setup do
  subscribe 'customer.subscription.created' do |event|
    customer_id = event.data.customer
    plan_id = event.data.plan.id

    Subscription.delay.create_from_stripe customer_id, plan_id
  end

  subscribe 'invoice.payment_succeeded' do |event|
    customer_id = event.data.customer
    invoice_details = {
      period_start: event.data.period_start,
      period_end: event.data.period_end,
      lines: event.data.lines,
      subtotal: event.data.subtotal,
      total: event.data.total
    }

    SubscriptionInvoice.delay.create_from_stripe customer_id, invoice_details
  end

  subscribe 'charge.failed' do |event|
    customer_id = event.data.customer
    BillingProfile.delay.handle_event_from_stripe customer_id, 'charge_failed'
  end
end
