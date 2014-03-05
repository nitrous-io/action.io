class Subscription < ActiveRecord::Base
  MAX_CHARGE_ATTEMPTS = 4

  attr_accessible :plan, :user, :pending_plan_id, :stripe_invoice_id

  belongs_to :billing_profile
  belongs_to :user
  belongs_to :plan
  belongs_to :pending_plan, class_name: 'Plan'
  has_one :n2o_fill, as: :resource

  validates_presence_of :plan

  scope :canceled,  -> { where(state: 'canceled') }

  state_machine initial: :pending do
    event(:activate)        { transition [:pending, :canceled] => :active }
    event(:cancel)          { transition :active => :canceled }

    after_transition on: :activate, do: :fill_n2o!
    after_transition on: :activate, do: :track_activation_on_mixpanel
    after_transition on: :activate, do: :notify_activation
    after_transition on: :activate, do: :update_box_premium

    # on cancel, release the n2o, put the boxes in delinquent mode and send an email
    after_transition on: :cancel, do: :empty_n2o!
    after_transition on: :cancel, do: :undelinquent_user!
    after_transition on: :cancel, do: :track_cancel_on_mixpanel
    after_transition on: :cancel, do: :update_box_premium
    after_transition on: :cancel, do: :notify_cancelation
    after_transition on: :cancel, do: :archive_past_subscription

    after_transition do |subscription|
      PushSubscriptionUpdatedJob.submit_job(subscription.id)
    end
  end

  def charge_failed(invoice)
    update_attribute :payment_due, true
    track_payment_failure_on_mixpanel
    send_payment_failure_notice_to_user(invoice)
    mark_as_delinquent_after_max_attempts(invoice)
  end

  def charge_succeeded
    return unless self.payment_due
    update_attribute :payment_due, false
    track_payment_reattempt_succeeded_on_mixpanel

    # Assumptions:
    # 1. Users are marked delinquent on first overdue month itself.
    # 2. Paying that invoice is enough to undelinquent the account.
    # Note: Stripe will keep creating invoices for following months,
    # but will not attempt to charge them.
    undelinquent_user!
  end

  def change_plan!(new_plan)
    current_plan = plan
    return false if new_plan == current_plan

    ActiveRecord::Base.transaction do
      empty_n2o!
      archive_past_subscription

      self.plan = new_plan
      self.save!

      fill_n2o!
      PushSubscriptionUpdatedJob.submit_job(self.id)
      notify_activation

      if new_plan.is_spec_downgrade_from(current_plan)
        DowngradeBoxesJob.submit_job(user.id)
      end

      if new_plan.is_price_downgrade_from(current_plan)
        TrackMixpanelEventJob.submit_job 'Downgraded Plan', user.id, from: current_plan.name, to: new_plan.name
      else
        TrackMixpanelEventJob.submit_job 'Upgraded Plan', user.id, from: current_plan.name, to: new_plan.name
      end
    end
  end

  def mark_as_delinquent_after_max_attempts(invoice)
    if (invoice.attempt_count == MAX_CHARGE_ATTEMPTS) && (invoice.next_payment_attempt == nil)
      user.delinquent!
    end
  end

  def undelinquent_user!
    user.undelinquent!
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
    user.visible_boxes(owner: true).each do |box|
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

  def notify_cancelation
    SubscriptionMailer.delay.subscription_canceled(id)
  end

  def send_payment_failure_notice_to_user(invoice)
    SubscriptionMailer.delay.payment_failed_alert(id,
                                                  attempt_count: invoice.attempt_count,
                                                  amount_due_cents: invoice.amount_due,
                                                  billing_period: formatted_billing_period(invoice)
                                                 )
  end

  def formatted_billing_period(invoice)
    period_start = Time.at(invoice.period_start.to_i)
    period_end = Time.at(invoice.period_end.to_i)

    "#{period_start.to_formatted_s(:billing_period)} - #{period_end.to_formatted_s(:billing_period)}"
  end

  def track_activation_on_mixpanel
    user_id = user.id
    coupon_code = user.coupon_code

    TrackMixpanelEventJob.submit_job 'Subscribed To Plan', user_id, plan: plan.name, coupon_code: coupon_code
    SetMixpanelPropertyJob.submit_job user_id, paid_user: true, plan: plan.name, canceled_subscription: false, coupon_code: coupon_code
  end

  def track_payment_failure_on_mixpanel
    user_id = user.id

    TrackMixpanelEventJob.submit_job 'Payment Failed', user_id, plan: plan.name
  end

  def track_payment_reattempt_succeeded_on_mixpanel
    user_id = user.id

    TrackMixpanelEventJob.submit_job 'Payment Reattempt Succeeded', user_id, plan: plan.name
  end

  def track_cancel_on_mixpanel
    user_id = user.id
    coupon_code = user.coupon_code

    TrackMixpanelEventJob.submit_job 'Unsubscribed From Plan', user_id, plan: plan.name, coupon_code: coupon_code
    SetMixpanelPropertyJob.submit_job user_id, paid_user: false, plan: nil, canceled_subscription: true, coupon_code: coupon_code
  end
end
