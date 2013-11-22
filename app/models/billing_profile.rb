class BillingProfile < ActiveRecord::Base
  attr_accessible :exp_month, :exp_year, :card_type, :last_four

  belongs_to :user
  has_many :subscriptions
  has_many :receipts

  before_save :change_plan
  after_save  :push_billing_profile_updated_message

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

  def cancel_subscription
    return false unless active_subscription

    if can_survive_with_base_n2o?
      if customer = retrieve_stripe_customer
        customer.cancel_subscription
      end

      true
    else
      self.errors.add :base, "You need to terminate boxes to free up N2O before downgrading from current plan. Please contact support with any questions"
      false
    end
  end

  def push_billing_profile_updated_message
    if self.persisted?
      Pusher["private-user-#{user.id}"].trigger('aio:billing_profile_updated', self.serialize_as_hash)
    end
  end

  def deliver_card_updated_mail
    SubscriptionMailer.delay.credit_card_changed_alert(self.id)
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

  def set_card_properties(stripe_id, card)
    self.last_four = card.last4
    self.card_type = card.type
    self.exp_month = card.exp_month
    self.exp_year  = card.exp_year
    self.stripe_id = stripe_id
    
    self.save
  end

  private

  def change_plan
    return if (new_record? || self.plan.nil?)

    # if selected plan results in having less n2o than currently utilised n2o
    # don't allow the plan change
    if selected_plan_has_less_n2o?
      self.errors.add :base, "You need to terminate boxes to free up N2O before downgrading to this plan. Please contact support with any questions"
      return false
    end

    if customer = retrieve_stripe_customer
      customer.update_subscription(plan: self.plan.stripe_id)
    end
  end

  def selected_plan_has_less_n2o?
    return false if active_subscription.nil?

    current_plan_n2o = active_subscription.subscription_plan.n2o_amount
    new_plan_n2o = self.plan.n2o_amount
    base_n2o = user.max_n2o - current_plan_n2o
    future_n2o = base_n2o + new_plan_n2o

    future_n2o < user.used_n2o
  end

  def can_survive_with_base_n2o?
    current_plan_n2o = active_subscription.subscription_plan.n2o_amount
    base_n2o = user.max_n2o - current_plan_n2o

    base_n2o >= user.used_n2o
  end

  def retrieve_stripe_customer
    @stripe_customer ||= Stripe::Customer.retrieve(self.stripe_id)
  end

end
