Stripe.api_key = ENV['STRIPE_SECRET_KEY']

StripeEvent.setup do
  subscribe 'customer.subscription.created' do |event|
    customer_id = event.data.customer
    plan_id = event.data.plan.id

    BillingProfile.delay.handle_event_from_stripe customer_id, 'subscription_created', { plan_id: plan_id }
  end

  subscribe 'customer.subscription.deleted' do |event|
    customer_id = event.data.customer

    BillingProfile.delay.handle_event_from_stripe customer_id, 'subscription_canceled'
  end

  subscribe 'charge.failed' do |event|
    customer_id = event.data.customer

    BillingProfile.delay.handle_event_from_stripe customer_id, 'charge_failed'
  end

  subscribe 'invoice.payment_succeeded' do |event|
    customer_id = event.data.customer
    receipt_details = {
      period_start: event.data.period_start,
      period_end: event.data.period_end,
      lines: event.data.lines.data,
      subtotal: event.data.subtotal,
      total: event.data.total
    }

    BillingProfile.delay.handle_event_from_stripe customer_id, 'payment_succeeded', { receipt_details: receipt_details }
  end
end
