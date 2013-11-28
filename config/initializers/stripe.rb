Stripe.api_key = ENV['STRIPE_SECRET_KEY']

StripeEvent.setup do
  subscribe 'customer.subscription.created' do |event|
    customer_id = event.data.object.customer
    plan_id = event.data.object.plan.id

    BillingProfile.delay.handle_stripe_event 'subscription_created', customer_id, { plan_id: plan_id }
  end

  subscribe 'customer.subscription.updated' do |event|
    customer_id = event.data.object.customer
    current_plan_id = event.data.object.plan.id
    previous_plan_id = event.data.previous_attributes.plan.id

    if current_plan_id != previous_plan_id
      BillingProfile.delay.handle_stripe_event 'subscription_changed', customer_id, { plan_id: current_plan_id, previous_plan_id: previous_plan_id }
    end
  end

  subscribe 'customer.subscription.deleted' do |event|
    customer_id = event.data.object.customer

    BillingProfile.delay.handle_stripe_event 'subscription_canceled', customer_id
  end

  subscribe 'customer.updated' do |event|
    if event.data.previous_attributes.default_card.present?
      customer_id = event.data.object.id
      BillingProfile.delay.handle_stripe_event 'card_updated', customer_id
    end
  end

  subscribe 'charge.failed' do |event|
    customer_id = event.data.object.customer

    BillingProfile.delay.handle_stripe_event 'charge_failed', customer_id
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

    BillingProfile.delay.handle_stripe_event 'payment_succeeded', customer_id, { receipt_details: receipt_details }
  end
end
