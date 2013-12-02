class Subscription < ActiveRecord::Base
  attr_accessible :plan

  belongs_to :billing_profile
  belongs_to :plan
  has_one :n2o_fill, as: :resource

  validates_presence_of :billing_profile_id, :plan

  scope :active, where(state: ['active', 'payment_due'])

  state_machine initial: :pending do
    event(:activate)        { transition [:pending] => :active }
    event(:payment_failed)  { transition [:active, :payment_due] => :payment_due }
    event(:cancel)          { transition [:active, :payment_due] => :canceled }

    after_transition on: :activate, do: :fill_n2o!
    after_transition on: :activate, do: :track_activation_on_mixpanel
    after_transition on: :activate, do: :notify_activation

    # on payment failed, send an email, add mixpanel event
    after_transition on: :payment_failed, do: :track_payment_failure_on_mixpanel
    after_transition on: :payment_failed, do: :notify_payment_failure

    # on cancel, release the n2o, put the boxes in delinquent mode and send an email
    after_transition on: :cancel, do: :empty_n2o!
    after_transition on: :cancel, do: :track_cancel_on_mixpanel

    after_transition do |subscription|
      subscription.billing_profile.push_billing_profile_updated_message
    end
  end

  private
  def fill_n2o!
    fill = build_n2o_fill
    fill.kind = N2oFill::Kind::PURCHASE
    fill.amount = plan.n2o_amount
    fill.user = billing_profile.user

    fill.save!
  end

  def empty_n2o!
    n2o_fill.try(:destroy)
  end

  def notify_activation
    SubscriptionMailer.delay.subscription_activated(id)
  end

  def notify_payment_failure
    SubscriptionMailer.delay.payment_failed_alert(id)
  end

  def track_activation_on_mixpanel
    user_id = billing_profile.user.id

    TrackMixpanelEventJob.submit_job 'Subscribed to a plan', user_id, {
      plan_name: plan.name
    }

    SetMixpanelPropertyJob.submit_job user_id, { paid_user: true, plan: plan.name }
  end

  def track_payment_failure_on_mixpanel
    user_id = billing_profile.user.id

    TrackMixpanelEventJob.submit_job 'Payment failed', user_id, { plan_name: plan.name }
  end

  def track_cancel_on_mixpanel
    user_id = billing_profile.user.id

    TrackMixpanelEventJob.submit_job 'Unsubscribed from a plan', user_id, {
      plan_name: plan.name
    }

    SetMixpanelPropertyJob.submit_job user_id, { paid_user: false, plan: nil }
  end
end
