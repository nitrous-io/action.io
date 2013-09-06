class Subscription < ActiveRecord::Base
  attr_accessible :subscription_plan

  belongs_to :billing_profile
  belongs_to :subscription_plan
  has_one :n2o_fill, as: :resource
  #belongs_to :coupon

  validates_presence_of :billing_profile_id, :subscription_plan_id

  scope :active,  where('state IN (?)', ['active', 'payment_due'])

  state_machine initial: :pending do
    event(:activate)          { transition [:pending]   => :active }
    event(:payment_failed)    { transition [:active, :payment_due] => :payment_due }
    event(:cancel)            { transition [:active, :payment_due] => :canceled }

    after_transition on: :activate, do: :fill_n2o!
    # on payment failed, send an email, add mixpanel event
    after_transition on: :payment_failed, do: :notify_payment_failure
    # on cancel, release the n2o, put the boxes in delinquent mode and send an email,
    after_transition on: :cancel, do: :empty_n2o!
    after_transition do |subscription|
      subscription.billing_profile.push_billing_profile_updated_message
    end
  end

  private
  def fill_n2o!
    fill = build_n2o_fill
    fill.kind = N2oFill::Kind::PURCHASE
    fill.amount = subscription_plan.n2o_amount
    fill.user = billing_profile.user

    fill.save!
  end

  def empty_n2o!
    n2o_fill.try(:destroy)
  end

  def notify_payment_failure
    SubscriptionMailer.delay.payment_failed_alert(id)
  end
end
