class Subscription < ActiveRecord::Base
  belongs_to :billing_profile
  belongs_to :subscription_plan
  #belongs_to :coupon

  validates_presence_of :billing_profile_id, :subscription_plan_id

  state_machine initial: :pending do
    event(:activate)          { transition [:pending]   => :active }
    event(:payment_failed)    { transition [:active, :payment_due] => :payment_due }
    event(:cancel)            { transition [:active, :payment_due] => :canceled }

    # on activate, fill n2o and send an email on subscription, add mixpanel event
    # on payment failed, send an email, add mixpanel event
    # on cancel, release the n2o, put the boxes in delinquent mode and send an email,
  end

  def self.create_from_stripe(customer_id, plan_id)
    subscription = Subscription.new
    subscription.billing_profile = BillingProfile.find_by_stripe_id customer_id
    subscription.subscription_plan = SubscriptionPlan.find_by_stripe_id plan_id

    subscription.activate!
  end
end
