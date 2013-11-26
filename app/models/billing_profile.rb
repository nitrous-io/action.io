class BillingProfile < ActiveRecord::Base
  attr_accessible :exp_month, :exp_year, :card_type, :last_four

  belongs_to :user
  has_many :subscriptions
  has_many :receipts

  # reason why we need such a method,
  # rather than having a single subscription association
  # is to maintain user's subscription history for reconcilation purposes.
  def active_subscription
    subscriptions.active.last
  end

  def active
    !!active_subscription
  end

  def expiry
    if exp_month && exp_year
      "#{exp_month}/#{exp_year}"
    end
  end

  def formatted_card_number
    "##############{last_four}"
  end

  def subscribe(stripe_token, plan)
    return false if active_subscription

    with_stripe_error_handling do
      if stripe_token && plan
        customer = Stripe::Customer.create(
          email: self.user.email,
          description: stripe_description,
          card: stripe_token,
          plan: plan.stripe_id
        )

        store_card_properties customer
        push_billing_profile_updated_message
      else
        self.errors.add :base, 'invalid request'
        false
      end
    end
  end

  def unsubscribe
    return false unless active_subscription
    with_stripe_error_handling do
      if can_survive_with_base_n2o?
        if customer = Stripe::Customer.retrieve(self.stripe_id)
          customer.cancel_subscription
        end

        true
      else
        self.errors.add :base, "You need to terminate boxes to free up N2O before downgrading from current plan. Please contact support with any questions"
        false
      end
    end
  end

  def update_subscription(stripe_token, plan)
    return false unless active_subscription
    with_stripe_error_handling do
      customer = Stripe::Customer.retrieve(self.stripe_id)

      # update user's credit card if a stripe token is provided
      if stripe_token.present?
        customer.card = stripe_token
        customer.save
        store_card_properties customer
        push_billing_profile_updated_message
      end

      return true unless plan

      # try to change the subscription plan, if a plan is provided
      if can_change_to? plan
        customer.update_subscription(plan: plan.stripe_id)
        true
      else
        self.errors.add :base, "You need to terminate boxes to free up N2O before downgrading to this plan. Please contact support with any questions"
        false
      end
    end
  end

  def push_billing_profile_updated_message
    Pusher["private-user-#{user.id}"].trigger('aio:billing_profile_updated', self.serialize_as_hash)
  end

  def deliver_card_updated_mail
    SubscriptionMailer.delay.credit_card_changed_alert(self.id)
  end

  def self.handle_stripe_event(event, customer_id, opts={})
    billing_profile = BillingProfile.find_by_stripe_id customer_id
    return unless billing_profile

    case event
    when 'subscription_created'
      # ignore if there's already an active subscription
      return if billing_profile.active

      plan = SubscriptionPlan.find_by_stripe_id opts[:plan_id]
      subscription = billing_profile.subscriptions.create plan: plan
      subscription.activate!
    when 'charge_failed'
      # send the payment failed notice only if there's an active subscription
      billing_profile.active_subscription.try(:payment_failed!)
    when 'subscription_changed'
      current_plan = billing_profile.active_subscription.subscription_plan
      billing_profile.active_subscription.cancel!

      new_plan = SubscriptionPlan.find_by_stripe_id opts[:plan_id]
      subscription = billing_profile.subscriptions.create plan: new_plan
      subscription.activate!

      if new_plan.is_downgrade_from(current_plan)
        DowngradeBoxesJob.submit_job(billing_profile.user.id)
      end
    when 'subscription_canceled'
      billing_profile.active_subscription.cancel!
      DowngradeBoxesJob.submit_job(billing_profile.user.id)
    when 'payment_succeeded'
      billing_profile.receipts.create opts[:receipt_details]
      user = billing_profile.user

      TrackMixpanelRevenueJob.submit_job(user.id, billing_profile.active_subscription.plan.price)
    when 'card_updated'
      billing_profile.deliver_card_updated_mail
    else
      Rails.logger.info "Cannot handle the Stripe event - #{event}"
    end
  end

  def self.find_profiles_with_expiring_cards(date)
    month = date.try(:month)
    year = date.try(:year)

    if month && year
      self.where(exp_month: month, exp_year: year).all.keep_if do |billing_profile|
        billing_profile.active
      end
    end
  end

  private
  def stripe_description
    "#{user.username} #{user.email}"
  end

  def store_card_properties(customer)
    self.last_four = customer.cards.data.first.last4
    self.card_type = customer.cards.data.first.type
    self.exp_month = customer.cards.data.first.exp_month
    self.exp_year  = customer.cards.data.first.exp_year
    self.stripe_id = customer.id

    save
  end

  # The new plan's n2o fill should be
  # more than or equal to user's currently utilized n2o.
  def can_change_to?(plan)
    return false if active_subscription.nil?

    current_plan_n2o = active_subscription.plan.n2o_amount
    new_plan_n2o = plan.n2o_amount
    base_n2o = user.max_n2o - current_plan_n2o
    future_n2o = base_n2o + new_plan_n2o

    future_n2o > user.used_n2o
  end

  def can_survive_with_base_n2o?
    current_plan_n2o = active_subscription.plan.n2o_amount
    base_n2o = user.max_n2o - current_plan_n2o

    base_n2o >= user.used_n2o
  end

  def with_stripe_error_handling(&block)
    yield
  rescue Stripe::CardError => e
    body = e.json_body
    err = body[:error]

    if err[:code] == "card_declined"
      error_message = "#{err[:message]} Try contacting your bank directly for assistance."
    else
      error_message = err[:message]
    end

    self.errors.add :base, error_message
    return false
  rescue Stripe::InvalidRequestError => e
    # Invalid parameters were supplied to Stripe's API
    self.errors.add :base, 'Invalid parameters'
    return false
  rescue Stripe::AuthenticationError => e
    # Authentication with Stripe's API failed
    # (maybe you changed API keys recently)
    self.errors.add :base, 'Cannot process your request at this time'
    # send an email to engineering?
    return false
  rescue Stripe::APIConnectionError => e
    # Network communication with Stripe failed
    self.errors.add :base, 'Cannot process your request at this time'
    return false
  rescue Stripe::StripeError => e
    self.errors.add :base, 'Cannot process your request at this time'
    # send an email to engineering?
    return false
  end
end
