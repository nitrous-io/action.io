class BillingProfile < ActiveRecord::Base
  attr_accessible :stripe_token, :plan

  belongs_to :user
  has_many :subscriptions
  has_many :receipts

  after_save :update_stripe

  attr_accessor :stripe_token, :plan

  def active_subscription
    subscriptions.active.last
  end

  def expiry
    if exp_month && exp_year
      "#{exp_month}/#{exp_year}"
    end
  end

  def formatted_card_number
    "##############{last_four}"
  end

  def self.handle_event_from_stripe(customer_id, event, opts={})
    billing_profile = BillingProfile.find_by_stripe_id customer_id
    return unless billing_profile

    case event
    when 'subscription_created'
      subscription_plan = SubscriptionPlan.find_by_stripe_id opts[:plan_id]
      subscription = billing_profile.subscriptions.create subscription_plan: subscription_plan
      subscription.activate!
    when 'charge_failed'
      billing_profile.active_subscription.payment_failed!
    when 'subscription_changed'
      billing_profile.active_subscription.cancel!

      subscription_plan = SubscriptionPlan.find_by_stripe_id opts[:plan_id]
      subscription = billing_profile.subscriptions.create subscription_plan: subscription_plan
      subscription.activate!
    when 'subscription_canceled'
      billing_profile.active_subscription.cancel!
    when 'payment_succeeded'
      billing_profile.receipts.create opts[:receipt_details]
    else
      Rails.logger.info "Cannot handle the Stripe event - #{event}"
    end
  end

  def change_plan(plan_id)
    new_plan = SubscriptionPlan.find plan_id
    ChangeStripePlanJob.submit_job stripe_id, new_plan.try(:stripe_id)
  end

  private
  def stripe_description
    "#{user.username} #{user.email}"
  end

  def update_stripe
    CreateOrUpdateStripeCustomerJob.submit_job id, user.email, stripe_description, stripe_token, plan.try(:id)

    # clear stripe token
    self.stripe_token = nil
  end
end
