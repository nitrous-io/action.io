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

    output = {
      recurring: { amount: 0, count: 0 },
      subscribed: { amount: 0, count: 0 },
      upgraded: { amount: 0, count: 0 },
      downgraded: { amount: 0, count: 0 },
      canceled: { amount: 0, count: 0 },
      overall: { amount: 0, count: 0 }
    }

    active_discounts.each do |discount|
      stripe_customer_id = discount.stripe_customer_id
      percent_off = discount.percent_off

      last_subscription_event = RevenueEvent.where("stripe_customer_id = ? AND event IN (?) AND created_at <= ?", discount.stripe_customer_id, subscription_events, period_end.end_of_day).order(:created_at).last
      next if last_subscription_event.nil?

      category = nil

      # when last subscription event has occurred before the period,
      # recognise it as a recurring discount.
      if last_subscription_event.created_at < period_start.beginning_of_day
        # ignore if the subscription is canceled
        if last_subscription_event.event != RevenueEvent::CANCELED
          category = :recurring
        end
      # when last subscription has occurred within the period
      # add it to correct event bracket
      else
        case last_subscription_event.event
        when RevenueEvent::SUBSCRIBED
          category = :subscribed
        when RevenueEvent::UPGRADED
          category = :upgraded
        when RevenueEvent::DOWNGRADED
          category = :downgraded
        when RevenueEvent::CANCELED
          category = :canceled
        end
      end

      # skip if the discount doesn't fit into a revenue category
      next if category.nil?

      stripe_plan_id = last_subscription_event.stripe_plan_id
      plan = Plan.find_by_stripe_id(stripe_plan_id)
      discount_value = plan.price_in_cents * (discount.percent_off / 100.0) * period_in_months

      output[category][:amount] += discount_value
      output[category][:count] += 1

      output[:overall][:amount] += discount_value
      output[:overall][:count] += 1
    end

   output
  end
end
