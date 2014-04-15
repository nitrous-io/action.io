class AppliedDiscount < ActiveRecord::Base
  attr_accessible :percent_off, :amount_off, :stripe_customer_id, :started_at, :ended_at

  scope :active_in_period, -> (period_start, period_end) do
    where("started_at < ? AND ended_at > ?", period_end.end_of_day, period_start.beginning_of_day)
  end

  def self.data_for_period(period_start, period_end)
    period_in_months = (12 * (period_end.year - period_start.year) + period_end.month - period_start.month) + 1

    subscription_events = [RevenueEvent::SUBSCRIBED, RevenueEvent::UPGRADED, RevenueEvent::DOWNGRADED, RevenueEvent::CANCELED]

    output = {
      starting: { amount: 0, count: 0 },
      subscribed: { amount: 0, count: 0 },
      upgraded: { amount: 0, count: 0 },
      downgraded: { amount: 0, count: 0 },
      canceled: { amount: 0, count: 0 },
      continuing: { amount: 0, count: 0 },
      total: { amount: 0, count: 0 }
    }

    day_before_period_start = period_start - 1
    active_discounts_at_start = self.where("started_at < ? AND ended_at > ?", day_before_period_start, day_before_period_start)
    active_discounts_at_start.each do |discount|
      stripe_customer_id = discount.stripe_customer_id
      percent_off = discount.percent_off

      # get the starting discount value
      last_subscription_event_before_period_start = RevenueEvent.where("stripe_customer_id = ? AND event IN (?) AND created_at <= ?", discount.stripe_customer_id, subscription_events, day_before_period_start).order(:created_at).last
      next if last_subscription_event_before_period_start.nil?

      next if last_subscription_event_before_period_start.event == RevenueEvent::CANCELED

      stripe_plan_id = last_subscription_event_before_period_start.stripe_plan_id
      plan = Plan.find_by_stripe_id(stripe_plan_id)
      next if plan.nil?

      output[:starting][:amount] += plan.price_in_cents * (discount.percent_off / 100.0)
      output[:starting][:count] += 1
    end

    active_discounts_in_period = self.active_in_period(period_start, period_end)
    active_discounts_in_period.each do |discount|
      last_subscription_event_before_period_end = RevenueEvent.where("stripe_customer_id = ? AND event IN (?) AND created_at <= ?", discount.stripe_customer_id, subscription_events, period_end.end_of_day).order(:created_at).last
      next if last_subscription_event_before_period_end.nil?

      category = nil

      # if there's no subscription event happened within the period
      # recognise it as a continuing discount.
      if last_subscription_event_before_period_end.created_at < period_start.beginning_of_day
        # reject if the subscription is canceled
        next if last_subscription_event_before_period_end.event == RevenueEvent::CANCELED

        category = :continuing
        stripe_plan_id = last_subscription_event_before_period_end.stripe_plan_id
        plan = Plan.find_by_stripe_id(stripe_plan_id)
        next if plan.nil?

        discount_value = plan.price_in_cents * (discount.percent_off / 100.0) * period_in_months
      # if there's a subscription event occurred within the period,
      # add it to correct event bracket.
      else
        # reject if the revenue event occurred after discount period ended
        next if last_subscription_event_before_period_end.created_at > discount.ended_at

        case last_subscription_event_before_period_end.event
        when RevenueEvent::SUBSCRIBED
          category = :subscribed
        when RevenueEvent::UPGRADED
          category = :upgraded
        when RevenueEvent::DOWNGRADED
          category = :downgraded
        when RevenueEvent::CANCELED
          category = :canceled
        end

        discount_value = last_subscription_event_before_period_end.amount * (discount.percent_off / 100.0) * period_in_months
      end

      # skip if the discount doesn't fit into a revenue category
      next if category.nil?

      output[category][:amount] += discount_value
      output[category][:count] += 1

      if category == :downgraded || category == :canceled
        output[:total][:amount] -= discount_value
      else
        output[:total][:amount] += discount_value
      end
    end

    output[:total][:count] = output[:continuing][:count] + output[:subscribed][:count] + output[:upgraded][:count] + output[:downgraded][:count]
    output
  end
end
