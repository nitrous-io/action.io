Stripe.api_key = ENV['STRIPE_SECRET_KEY']

StripeEvent.setup do
  subscribe 'customer.subscription.created' do |event|
    customer_id = event.data.object.customer
    plan_id = event.data.object.plan.id

    BillingProfile.delay.handle_event_from_stripe customer_id, 'subscription_created', { plan_id: plan_id }
  end

  subscribe 'customer.subscription.updated' do |event|
    customer_id = event.data.object.customer
    current_plan_id = event.data.object.plan.id
    previous_plan_id = event.data.previous_attributes.plan.id

    if current_plan_id != previous_plan_id
      BillingProfile.delay.handle_event_from_stripe customer_id, 'subscription_changed', { plan_id: current_plan_id }
    end
  end

  subscribe 'customer.subscription.deleted' do |event|
    customer_id = event.data.object.customer

    BillingProfile.delay.handle_event_from_stripe customer_id, 'subscription_canceled'
  end

  subscribe 'charge.failed' do |event|
    customer_id = event.data.object.customer

    BillingProfile.delay.handle_event_from_stripe customer_id, 'charge_failed'
  end

  subscribe 'invoice.payment_succeeded' do |event|
    customer_id = event.data.object.customer
    receipt_details = {
      period_start: event.data.object.period_start,
      period_end: event.data.object.period_end,
      lines: event.data.object.lines.data,
      subtotal: event.data.object.subtotal,
      total: event.data.object.total
    }

    BillingProfile.delay.handle_event_from_stripe customer_id, 'payment_succeeded', { receipt_details: receipt_details }
  end
end
