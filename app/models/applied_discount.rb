class AppliedDiscount < ActiveRecord::Base
  SUBSCRIPTION_EVENTS = [RevenueEvent::SUBSCRIBED, RevenueEvent::UPGRADED, RevenueEvent::DOWNGRADED, RevenueEvent::CANCELED]

  attr_accessible :percent_off, :amount_off, :stripe_customer_id, :stripe_event_id, :started_at, :ended_at

  def self.total_discounted_value_as_of(date)
    relevant_events = RevenueEvent.where(event: SUBSCRIPTION_EVENTS).where('created_at <= ?', date).order(:created_at)
    output = { amount: 0, count: 0 }

    self.where("started_at < ? AND ended_at >= ?", date, date).each do |discount|
      last_subscription_event = relevant_events.
      where(stripe_customer_id: discount.stripe_customer_id).last

      next if last_subscription_event.nil? || last_subscription_event.event == RevenueEvent::CANCELED || (last_subscription_event.created_at > discount.ended_at)

      stripe_plan_id = last_subscription_event.stripe_plan_id
      plan = Plan.find_by_stripe_id(stripe_plan_id)
      next if plan.nil?

      output[:amount] += (plan.price_in_cents * (discount.percent_off / 100.0)).round
      output[:count] += 1
    end

    output
  end
end
