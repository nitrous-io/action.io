class BillingProfile < ActiveRecord::Base
  attr_accessible :exp_month, :exp_year, :card_type, :last_four

  belongs_to :user
  has_many :receipts

  # for reconciliation purposes,
  # we got multiple subscriptions
  # for a billing profile.
  has_many :subscriptions

  # However, there can be only one
  # active subscription for a billing profile
  # at a given time.
  #
  # if you want to access active subscription of the profile,
  # use the `active_subscription` method.
  def active_subscription
    subscriptions.active.last
  end

  # if you want to check if the profile is active,
  # use the `active` method.
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

  def push_billing_profile_updated_message
    if self.persisted?
      Pusher["private-user-#{user.id}"].trigger('aio:billing_profile_updated', self.serialize_as_hash)
    end
  end

  def deliver_card_updated_mail
    SubscriptionMailer.delay.credit_card_changed_alert(self.id)
  end

  def store_credit_card_attributes(stripe_id, card)
    self.last_four = card.last4
    self.card_type = card.type
    self.exp_month = card.exp_month
    self.exp_year  = card.exp_year
    self.stripe_id = stripe_id

    self.save
  end

  def can_change_to_plan?(plan)
    return false if active_subscription.nil?

    current_plan_n2o = active_subscription.subscription_plan.n2o_amount
    new_plan_n2o = plan.n2o_amount
    base_n2o = user.max_n2o - current_plan_n2o
    future_n2o = base_n2o + new_plan_n2o

    future_n2o < user.used_n2o
  end

  def can_cancel_subscription?
    current_plan_n2o = active_subscription.subscription_plan.n2o_amount
    base_n2o = user.max_n2o - current_plan_n2o

    base_n2o >= user.used_n2o
  end

  def self.handle_event_from_stripe(customer_id, event, opts={})
    billing_profile = BillingProfile.find_by_stripe_id customer_id
    return unless billing_profile

    case event
    when 'subscription_created'
      # ignore if there's already an active subscription
      return if billing_profile.active_subscription.present?

      subscription_plan = SubscriptionPlan.find_by_stripe_id opts[:plan_id]
      subscription = billing_profile.subscriptions.create subscription_plan: subscription_plan
      subscription.activate!
    when 'charge_failed'
      # send the payment failed notice only if there's an active subscription
      billing_profile.active_subscription.try(:payment_failed!)
    when 'subscription_changed'
      billing_profile.active_subscription.cancel!

      subscription_plan = SubscriptionPlan.find_by_stripe_id opts[:plan_id]
      subscription = billing_profile.subscriptions.create subscription_plan: subscription_plan
      subscription.activate!
    when 'subscription_canceled'
      billing_profile.active_subscription.cancel!
    when 'payment_succeeded'
      billing_profile.receipts.create opts[:receipt_details]
      user = billing_profile.user

      TrackMixpanelRevenueJob.submit_job(user.id, billing_profile.active_subscription.subscription_plan.price)
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
end
