class AppliedDiscount < ActiveRecord::Base
  SUBSCRIPTION_EVENTS = [RevenueEvent::SUBSCRIBED, RevenueEvent::UPGRADED, RevenueEvent::DOWNGRADED, RevenueEvent::CANCELED]

  attr_accessible :percent_off, :amount_off, :stripe_customer_id, :stripe_event_id, :started_at, :ended_at

  scope :active_in_period, -> (period_start, period_end) do
    where("started_at < ? AND ended_at > ?", period_end.end_of_day, period_start.beginning_of_day)
  end

  def self.discounted_value_as_of(date)
    relevant_events = RevenueEvent.where(event: SUBSCRIPTION_EVENTS).where('created_at < ?', date).order(:created_at)
    output = { amount: 0, count: 0 }

    self.where("started_at < ? AND ended_at >= ?", date, date).each do |discount|
      last_subscription_event = relevant_events.
        where(stripe_customer_id: discount.stripe_customer_id).last

      next if last_subscription_event.nil? || last_subscription_event.event == RevenueEvent::CANCELED || (last_subscription_event.created_at > discount.ended_at)

      stripe_plan_id = last_subscription_event.stripe_plan_id
      plan = Plan.find_by_stripe_id(stripe_plan_id)
      next if plan.nil?

      increment(output, rounded_discount(plan.price_in_cents, discount))
    end

    output
  end

  def self.data_for_period(period_start, period_end)
    period_in_months = (12 * (period_end.year - period_start.year) + period_end.month - period_start.month) + 1

    output = {
      starting: { amount: 0, count: 0 },
      subscribed: { amount: 0, count: 0 },
      upgraded: { amount: 0, count: 0 },
      downgraded: { amount: 0, count: 0 },
      canceled: { amount: 0, count: 0 },
      added: { amount: 0, count: 0 },
      expired: { amount: 0, count: 0 },
      total: { amount: 0, count: 0 }
    }

    output[:starting] = self.discounted_value_as_of period_start.beginning_of_day

    relevant_events = RevenueEvent.where(event: SUBSCRIPTION_EVENTS).where('created_at <= ?', period_end.end_of_day).order(:created_at)
    self.active_in_period(period_start, period_end).each do |discount|
      last_subscription_event = relevant_events.
        where(stripe_customer_id: discount.stripe_customer_id).last
      next if last_subscription_event.nil?

      category = nil

      # if the discount doesn't carry beyond the period,
      # recognise it as an expired discount.
      if (discount.ended_at <= period_end.end_of_day) &&
        (last_subscription_event.created_at <= discount.ended_at) &&
        (last_subscription_event.event != RevenueEvent::CANCELED)

        stripe_plan_id = last_subscription_event.stripe_plan_id
        plan = Plan.find_by_stripe_id(stripe_plan_id)

        if plan.present?
          increment(output[:expired], rounded_discount(plan.price_in_cents, discount) * period_in_months)
        end
      end

      if (last_subscription_event.created_at < period_start.beginning_of_day)
        # reject if the subscription is already canceled
        next if last_subscription_event.event == RevenueEvent::CANCELED

        # check if it is a manually added discounts to an existing subscription.
        if (discount.started_at >= period_start.beginning_of_day)
          category = :added
          stripe_plan_id = last_subscription_event.stripe_plan_id
          plan = Plan.find_by_stripe_id(stripe_plan_id)
          next if plan.nil?

          discount_value = rounded_discount(plan.price_in_cents, discount) * period_in_months
        end
      # if there's a subscription event occurred within the period,
      # add it to correct event bracket.
      else
        # reject if the revenue event occurred after discount period ended
        next if last_subscription_event.created_at > discount.ended_at
        category = category_for_event(last_subscription_event)

        discount_value = rounded_discount(last_subscription_event.amount, discount) * period_in_months
      end

      # skip if the discount doesn't fit into a revenue category
      next if category.nil?

      increment(output[category], discount_value)
    end

    output[:total][:amount] = output[:starting][:amount] + output[:subscribed][:amount] - output[:canceled] [:amount] +
                              output[:upgraded][:amount] - output[:downgraded][:amount] +
                              output[:added] [:amount] - output[:expired][:amount]

    output[:total][:count] = output[:starting][:count] + output[:subscribed][:count] - output[:canceled] [:count] +
                             output[:added] [:count] - output[:expired][:count]

    output
  end

  def self.increment(h, amount)
    h[:amount] += amount
    h[:count] += 1
  end

  def self.category_for_event(revent)
    case revent.event
    when RevenueEvent::SUBSCRIBED
      :subscribed
    when RevenueEvent::UPGRADED
      :upgraded
    when RevenueEvent::DOWNGRADED
      :downgraded
    when RevenueEvent::CANCELED
      :canceled
    else
      nil
    end
  end

  # Stripe rounds off discount values to the nearest cent, so we do the same.
  def self.rounded_discount(amount_in_cents, discount)
    discount = amount_in_cents * (discount.percent_off / 100.0)
    discount.round
  end
end
