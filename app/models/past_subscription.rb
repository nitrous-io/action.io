class PastSubscription < ActiveRecord::Base
  attr_accessible :user, :plan_name, :plan_stripe_id, :plan_price, :plan_interval, :plan_n2o_amount

  belongs_to :user

  def self.archive(subscription)
    create(
      user: subscription.user,
      plan_name: subscription.plan.name,
      plan_stripe_id: subscription.plan.stripe_id,
      plan_price: subscription.plan.price,
      plan_interval: subscription.plan.interval,
      plan_n2o_amount: subscription.plan.n2o_amount,
    )
  end
end
