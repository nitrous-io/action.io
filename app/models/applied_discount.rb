class AppliedDiscount < ActiveRecord::Base
  attr_accessible :percent_off, :amount_off, :stripe_customer_id, :started_at, :ended_at

  scope :active_in_period, -> (period_start, period_end) do
    where("started_at < ? AND ended_at > ?", period_end.end_of_day, period_start.beginning_of_day)
  end

  def self.data_for_period(period_start, period_end)
    period_in_months = (12 * (period_end.year - period_start.year) + period_end.month - period_start.month) + 1
    active_discounts = self.active_in_period(period_start, period_end)

    # for each active discount
    #  -- get the subscription plan of the customer at the end of the given period
    #  -- calculate the discount value for the subscription
    #  -- discount value x period_in_months
    subscription_events = [RevenueEvent::SUBSCRIBED, RevenueEvent::UPGRADED, RevenueEvent::DOWNGRADED, RevenueEvent::CANCELED]

    total = 0
    count = 0

    active_discounts.each do |discount|
      stripe_customer_id = discount.stripe_customer_id
      percent_off = discount.percent_off

      last_subscription_event = RevenueEvent.where("stripe_customer_id = ? AND event IN (?) AND created_at <= ?", discount.stripe_customer_id, subscription_events, period_end.end_of_day).last
      # if the subscription is canceled ignore the discount
      if last_subscription_event.event != RevenueEvent::CANCELED
        stripe_plan_id = last_subscription_event.stripe_plan_id
        plan = Plan.find_by_stripe_id(stripe_plan_id)
        discount_value = plan.price_in_cents * (discount.percent_off / 100.0)
        total += (discount_value * period_in_months)
        count += 1
      end
   end

    { amount: total, count: count }
  end
end
