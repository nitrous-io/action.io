class StripeWebhookHandler
  def self.subscription_created(event)
    customer_id = event.data.object.customer
    plan_id = event.data.object.plan.id

    user = User.find_by_stripe_customer_id(customer_id)
    return unless user

    plan = Plan.find_by_stripe_id(plan_id)
    return unless plan

    s = user.build_subscription plan: plan
    s.activate!
  end

  def self.subscription_updated(event)
    customer_id = event.data.object.customer
    plan_id = event.data.object.plan.id

    user = User.find_by_stripe_customer_id(customer_id)
    return unless user

    plan = Plan.find_by_stripe_id(plan_id)
    return unless plan

    user.apply_plan_change(plan)
  end

  def self.payment_succeeded(event)
    customer_id = event.data.object.customer

    user = User.find_by_stripe_customer_id(customer_id)
    return unless user

    user.billing_profile.receipts.create(
      period_start: event.data.object.period_start,
      period_end: event.data.object.period_end,
      lines: event.data.object.lines.data,
      subtotal: event.data.object.subtotal,
      total: event.data.object.total
    )

    total_in_currency = event.data.object.total/ 100.0
    TrackMixpanelRevenueJob.submit_job(user.id, total_in_currency)
  end

  def self.charge_failed(event)
    customer_id = event.data.object.customer

    user = User.find_by_stripe_customer_id(customer_id)
    return unless user

    if subscription = user.subscription
      subscription.charge_failed
    end
  end
end

