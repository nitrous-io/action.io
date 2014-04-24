class StripeWebhookHandler
  def self.subscription_created(event)
    customer_id = event.data.object.customer
    plan_id = event.data.object.plan.id

    plan = Plan.find_by_stripe_id(plan_id)
    return unless plan

    if plan.trial_period_days.blank?
      RevenueEvent.create event: RevenueEvent::SUBSCRIBED,
                          amount: plan.price_in_cents,
                          created_at: Time.at(event.created),
                          stripe_id: event.id,
                          subscription_started_at: Time.at(event.data.object.start),
                          stripe_customer_id: customer_id,
                          stripe_plan_id: plan_id
    end

    user = User.find_by_stripe_customer_id(customer_id)
    return unless user

    user.apply_subscription(plan)
  end

  def self.subscription_updated(event)
    customer_id = event.data.object.customer
    new_plan_id = event.data.object.plan.id
    old_plan_id = event.data.previous_attributes.plan.id

    new_plan = Plan.find_by_stripe_id(new_plan_id)
    return unless new_plan

    old_plan = Plan.find_by_stripe_id(old_plan_id)

    # track revenue event
    price_change = new_plan.price_in_cents - old_plan.price_in_cents
    event_type = (price_change > 0) ? RevenueEvent::UPGRADED : RevenueEvent::DOWNGRADED
    amount = price_change.abs
    RevenueEvent.create event: event_type,
                        amount: amount,
                        created_at: Time.at(event.created),
                        stripe_id: event.id,
                        subscription_started_at: Time.at(event.data.object.start),
                        stripe_customer_id: customer_id,
                        stripe_plan_id: new_plan_id

    user = User.find_by_stripe_customer_id(customer_id)
    return unless user

    user.apply_plan_change(new_plan)
  end

  def self.subscription_deleted(event)
    plan_id = event.data.object.plan.id
    plan = Plan.find_by_stripe_id(plan_id)
    return unless plan

    if plan.trial_period_days.blank?
      RevenueEvent.create event: RevenueEvent::CANCELED,
                          amount: plan.price_in_cents,
                          created_at: Time.at(event.created),
                          stripe_id: event.id,
                          subscription_started_at: Time.at(event.data.object.start),
                          stripe_customer_id: event.data.object.customer,
                          stripe_plan_id: plan_id

    end
  end

  def self.payment_succeeded(event)
    customer_id = event.data.object.customer
    invoice_id = event.data.object.id

    user = User.find_by_stripe_customer_id(customer_id)
    return unless user

    # if there's pending subscription for the given invoice id,
    # send the request to change the plan now.
    user.process_pending_upgrade(invoice_id)

    user.billing_profile.receipts.create(
      period_start: event.data.object.period_start,
      period_end: event.data.object.period_end,
      lines: event.data.object.lines.data,
      subtotal: event.data.object.subtotal,
      total: event.data.object.total
    )

    user.subscription.try(:charge_succeeded)

    total_in_currency = event.data.object.total / 100.0
    TrackMixpanelRevenueJob.submit_job(user.id, total_in_currency)
  end

  def self.invoice_created(event)
    RevenueEvent.create event: RevenueEvent::BILLED, amount: event.data.object.total, created_at: Time.at(event.created), stripe_id: event.id
  end

  def self.charge_succeeded(event)
    RevenueEvent.create event: RevenueEvent::CHARGED, amount: event.data.object.amount, created_at: Time.at(event.created), stripe_id: event.id
  end

  def self.charge_failed(event)
    customer_id = event.data.object.customer
    invoice_id = event.data.object.invoice

    user = User.find_by_stripe_customer_id(customer_id)
    return unless user

    # Try to fetch the associated invoice
    # We don't care about the charge failures without an associated invoice.
    # (eg. manual refunds that failed)
    invoice = Stripe::Invoice.retrieve invoice_id
    return unless invoice

    if subscription = user.subscription
      subscription.charge_failed(invoice)
    end
  end

  def self.charge_refunded(event)
    RevenueEvent.create event: RevenueEvent::REFUNDED, amount: event.data.object.amount_refunded, created_at: Time.at(event.created), stripe_id: event.id
  end

  def self.discount_created(event)
    discount_object = event.data.object
    AppliedDiscount.create! percent_off: discount_object.coupon.percent_off,
                            stripe_customer_id: discount_object.customer,
                            started_at: Time.at(discount_object.start),
                            ended_at: Time.at(discount_object.end)
  end
end
