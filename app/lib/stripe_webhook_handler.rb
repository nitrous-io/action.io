class StripeWebhookHandler
  def self.subscription_created(event)
    customer_id = event.data.object.customer
    plan_id = event.data.object.plan.id

    plan = Plan.find_by_stripe_id(plan_id)
    return unless plan

    user = User.find_by_stripe_customer_id(customer_id)
    return unless user

    user.apply_subscription(plan)
  end

  def self.subscription_updated(event)
    customer_id = event.data.object.customer
    new_plan_id = event.data.object.plan.id

    new_plan = Plan.find_by_stripe_id(new_plan_id)
    return unless new_plan

    user = User.find_by_stripe_customer_id(customer_id)
    return unless user

    user.apply_change_plan(new_plan)
  end

  def self.subscription_trial_will_end(event)
    customer_id = event.data.object.customer

    user = User.find_by_stripe_customer_id(customer_id)
    return unless user

    # As at the time of implementation, only users subscribed through AWS Activate program
    # should have an eligible trial period.
    if user.aws_activate_plans_enabled
      SubscriptionMailer.subscription_trial_expiring_alert(user.id).deliver
      TrackMixpanelEventJob.submit_job 'Subscription Trial Expiring Alert Sent', user.id

      # Change user from AWS Activate plan group to the default plan group
      user.update_attribute 'plan_group_id', nil
    end
  end

  def self.payment_succeeded(event)
    customer_id = event.data.object.customer
    invoice_id = event.data.object.id

    user = User.find_by_stripe_customer_id(customer_id)
    return unless user

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
end
