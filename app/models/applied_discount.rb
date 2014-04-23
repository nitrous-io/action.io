class AppliedDiscount < ActiveRecord::Base
  SUBSCRIPTION_EVENTS = [RevenueEvent::SUBSCRIBED, RevenueEvent::UPGRADED, RevenueEvent::DOWNGRADED, RevenueEvent::CANCELED]

  attr_accessible :percent_off, :amount_off, :stripe_customer_id, :stripe_event_id, :started_at, :ended_at

  scope :active_in_period, -> (period_start, period_end) do
    where("started_at < ? AND ended_at > ?", period_end, period_start)
  end

  def self.discounted_value_as_of(time)
    relevant_events = subscription_events_before(time)
    output = { amount: 0, count: 0 }

    self.where("started_at < ? AND ended_at >= ?", time, time).each do |discount|
      last_subscription_event = relevant_events.
        where(stripe_customer_id: discount.stripe_customer_id).last

      raise "No matching event for discount. Discount: #{discount.inspect}, event: #{last_subscription_event.inspect}" if last_subscription_event.nil?
      raise "Discount ended before last subscription event. Discount: #{discount.inspect}, event: #{last_subscription_event.inspect}" if discount.ended_at < last_subscription_event.created_at
      next if last_subscription_event.event == RevenueEvent::CANCELED

      # FIXME We should not rely on the local Plan record - the price should come from Stripe instead.
      plan = Plan.find_by_stripe_id(last_subscription_event.stripe_plan_id)
      raise "Discount has no associated plan. Discount: #{discount.inspect}, event: #{last_subscription_event.inspect}" if plan.nil?

      increment(output, rounded_discount(plan.price_in_cents, discount))
    end

    output
  end

  def self.data_for_period(period_start, period_end)
    start_time = period_start.beginning_of_day
    end_time = period_end.end_of_day
    # FIXME Date calculation here should rely on a date math library or a tested helper.
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

    output[:starting] = discounted_value_as_of(start_time)

    relevant_events = subscription_events_before(end_time)
    active_discounts = active_in_period(start_time, end_time)

    active_discounts.each do |discount|
      last_subscription_event = relevant_events.
        where(stripe_customer_id: discount.stripe_customer_id).last
      next if last_subscription_event.nil?

      # Ignore discounts where the subscription was canceled before the period.
      next if last_subscription_event.event == RevenueEvent::CANCELED &&
        last_subscription_event.created_at < start_time

      # --- Expired discounts ---
      # These are discounts that expire within the period (i.e. the discount
      # was valid at the start, but expired before the end of the period).
      if discount.ended_at <= end_time
        last_subscription_event_before_discount_expiry = subscription_events_before(discount.ended_at).
          where(stripe_customer_id: discount.stripe_customer_id).last

        plan = Plan.find_by_stripe_id(last_subscription_event_before_discount_expiry.stripe_plan_id)
        raise "Expired discount has no associated plan. Discount: #{discount.inspect}, event: #{last_subscription_event_before_discount_expiry.inspect}" if plan.nil?
        increment(output[:expired], rounded_discount(plan.price_in_cents, discount) * period_in_months)
      end

      # --- Added discounts ---
      # These are discounts that were added manually. These are identified by:
      # 1. last subscription event occurred before the start of the period
      # 2. discount started after the start of the period.
      if last_subscription_event.created_at < start_time
        if discount.started_at >= start_time
          # FIXME We should not rely on the local Plan record - the price should come from Stripe instead.
          plan = Plan.find_by_stripe_id(last_subscription_event.stripe_plan_id)
          raise "Added discount has no associated plan. Discount: #{discount.inspect}, event: #{last_subscription_event.inspect}" if plan.nil?
          increment(output[:added], rounded_discount(plan.price_in_cents, discount) * period_in_months)
        else
          # 1. Last subscription event occurred before the start of the period,
          # 2. discount started before the start of the period.
          # This means it's either included in the starting MRR or an expired
          # discount.
          #
          # FIXME Too many code paths and not sure if all are covered ಠ_ಠ
          next
        end
      else
        # --- "Normal" discounts ---
        # These are discounts that are applied to new subscriptions,
        # cancelations, upgrades and downgrades.

        # FIXME Can we actually ignore these below?
        # reject if event occurred after discount period ended
        next if last_subscription_event.created_at > discount.ended_at

        events_within_period = relevant_events
          .where(stripe_customer_id: discount.stripe_customer_id)
          .where('created_at >= ?', start_time)
          .where('created_at >= ?', discount.started_at)
          .where('created_at < ?', discount.ended_at)

        events_within_period.each do |event|
          category = category_for_event(event)
          raise "Uncategorized discount - this should not happen. Discount: #{discount.inspect}" if category.nil?

          increment(output[category], rounded_discount(event.amount, discount) * period_in_months)
        end
      end
    end

    output[:total][:amount] = output[:starting][:amount] + output[:subscribed][:amount] - output[:canceled][:amount] +
                              output[:upgraded][:amount] - output[:downgraded][:amount] +
                              output[:added][:amount] - output[:expired][:amount]

    output[:total][:count] = output[:starting][:count] + output[:subscribed][:count] - output[:canceled][:count] +
                             output[:added][:count] - output[:expired][:count]

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

  def self.subscription_events_before(date)
    RevenueEvent.where(event: SUBSCRIPTION_EVENTS).where('created_at <= ?', date).order(:created_at)
  end
end
