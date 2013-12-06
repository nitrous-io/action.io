class Subscription < ActiveRecord::Base
  attr_accessible :plan, :user

  belongs_to :billing_profile
  belongs_to :user
  belongs_to :plan
  has_one :n2o_fill, as: :resource

  validates_presence_of :user_id, :plan

  scope :active, where(state: ['active', 'payment_due'])

  state_machine initial: :pending do
    event(:activate)        { transition [:pending, :canceled] => :active }
    event(:payment_failed)  { transition [:active, :payment_due] => :payment_due }
    event(:cancel)          { transition [:active, :payment_due] => :canceled }

    after_transition on: :activate, do: :fill_n2o!
    after_transition on: :activate, do: :track_activation_on_mixpanel
    after_transition on: :activate, do: :notify_activation
    after_transition on: :activate, do: :update_box_premium

    # on payment failed, send an email, add mixpanel event
    after_transition on: :payment_failed, do: :track_payment_failure_on_mixpanel
    after_transition on: :payment_failed, do: :notify_payment_failure

    # on cancel, release the n2o, put the boxes in delinquent mode and send an email
    after_transition on: :cancel, do: :empty_n2o!
    after_transition on: :cancel, do: :track_cancel_on_mixpanel
    after_transition on: :cancel, do: :update_box_premium
    after_transition on: :cancel, do: :archive_past_subscription

    after_transition do |subscription|
      # subscription.billing_profile.push_billing_profile_updated_message
    end
  end

  def change_plan(new_plan)
    current_plan = self.plan
    subscription.cancel
    subscription.plan = plan
    subscription.activate!

    if new_plan.is_downgrade_from(current_plan)
      DowngradeBoxesJob.submit_job(user.id)
    end
  end

  private
  def fill_n2o!
    fill = build_n2o_fill
    fill.kind = N2oFill::Kind::PURCHASE
    fill.amount = plan.n2o_amount
    fill.user = user

    fill.save!
  end

  def update_box_premium
    user.owned_boxes.each do |box|
      box.update_premium
    end
  end

  def empty_n2o!
    n2o_fill.try(:destroy)
  end

  # Saves this subscription as a PastSubscription.
  def archive_past_subscription
    PastSubscription.archive(self)
  end

  def notify_activation
    SubscriptionMailer.delay.subscription_activated(id)
  end

  def notify_payment_failure
    SubscriptionMailer.delay.payment_failed_alert(id)
  end

  def track_activation_on_mixpanel
    user_id = user.id

    TrackMixpanelEventJob.submit_job 'Subscribed To Plan', user_id, plan: plan.name
    SetMixpanelPropertyJob.submit_job user_id, { paid_user: true, plan: plan.name }
  end

  def track_payment_failure_on_mixpanel
    user_id = user.id

    TrackMixpanelEventJob.submit_job 'Payment Failed', user_id, plan: plan.name
  end

  def track_cancel_on_mixpanel
    user_id = user.id

    TrackMixpanelEventJob.submit_job 'Unsubscribed From Plan', user_id, plan: plan.name
    SetMixpanelPropertyJob.submit_job user_id, paid_user: false, plan: nil
  end
end
