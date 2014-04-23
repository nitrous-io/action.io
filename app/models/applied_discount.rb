class AppliedDiscount < ActiveRecord::Base
  SUBSCRIPTION_EVENTS = [RevenueEvent::SUBSCRIBED, RevenueEvent::UPGRADED, RevenueEvent::DOWNGRADED, RevenueEvent::CANCELED]

  attr_accessible :percent_off, :amount_off, :stripe_customer_id, :stripe_event_id, :started_at, :ended_at

  scope :active_in_period, -> (period_start, period_end) do
    where("started_at < ? AND ended_at > ?", period_end.end_of_day, period_start.beginning_of_day)
  end

  def revenue_discounts_for_period(started, ended)
    output = {
      subscribed: { amount: 0, count: 0 },
      upgraded: { amount: 0, count: 0 },
      downgraded: { amount: 0, count: 0 },
      canceled: { amount: 0, count: 0 }
    }

    period_end_or_expiry_date = [ ended.end_of_day, self.ended_at ].min
    relevant_events = subscription_events_before(period_end_or_expiry_date).
        where(stripe_customer_id: self.stripe_customer_id)

    relevant_events.each do |revent|
      category = nil

      case revent.event
      when RevenueEvent::SUBSCRIBED
        category = :subscribed
      when RevenueEvent::UPGRADED
        category = :upgraded
      when RevenueEvent::DOWNGRADED
        category = :downgraded
      when RevenueEvent::CANCELED
        category = :canceled
      else
        next
      end

      discounted_value = revent.amount * (self.percent_off / 100.0)
      increment output[category], discounted_value
    end

    output
  end

  def self.discounted_value_as_of(date)
    relevant_events = subscription_events_before(date)
    output = { amount: 0, count: 0 }

    self.where("started_at < ? AND ended_at >= ?", date, date).each do |discount|
      last_subscription_event = relevant_events.
        where(stripe_customer_id: discount.stripe_customer_id).last

      Rails.logger.info "****no matching subscription #{discount.stripe_event_id}" if last_subscription_event.nil?
      Rails.logger.info "****discount ended before last subscription event #{discount.stripe_event_id}" if (last_subscription_event.created_at > discount.ended_at)

      next if last_subscription_event.event == RevenueEvent::CANCELED

      stripe_plan_id = last_subscription_event.stripe_plan_id
      plan = Plan.find_by_stripe_id(stripe_plan_id)
      Rails.logger.info "****no plan found #{discount.stripe_event_id} #{stripe_plan_id}" if plan.nil?
      next if plan.nil?

      increment(output, plan.price_in_cents * (discount.percent_off / 100.0))
    end

    output
  end

  def self.data_for_period(period_start, period_end)
    # move to a helper
    # period_in_months = (12 * (period_end.year - period_start.year) + period_end.month - period_start.month) + 1
    period_in_months = 1

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

    relevant_events = subscription_events_before(period_end.end_of_day)
    self.active_in_period(period_start, period_end).each do |discount|
      last_subscription_event = relevant_events.
        where(stripe_customer_id: discount.stripe_customer_id).last
      Rails.logger.info "**last subscription was nil #{discount.stripe_event_id}" if last_subscription_event.nil?
      #next if last_subscription_event.nil?

      category = nil
      discount_value = nil

      # if the discount doesn't carry beyond the period,
      # recognise it as an expired discount.
      if (discount.ended_at <= period_end.end_of_day)

        last_subscription_event_before_discount_expiry = subscription_events_before(discount.ended_at).last

        stripe_plan_id = last_subscription_event_before_discount_expiry.stripe_plan_id
        plan = Plan.find_by_stripe_id(stripe_plan_id)

        if plan.present?
          increment(output[:expired], plan.price_in_cents * (discount.percent_off / 100.0) * period_in_months)
        else
          Rails.logger.info "** Plan not present #{discount.stripe_event_id}"
        end
      end

      if (last_subscription_event.created_at < period_start.beginning_of_day)
        # reject if the subscription is already canceled
        next if last_subscription_event.event == RevenueEvent::CANCELED

        # check if it is a manually added discount to an existing subscription.
        if (discount.started_at >= period_start.beginning_of_day)
          category = :added
          stripe_plan_id = last_subscription_event.stripe_plan_id
          plan = Plan.find_by_stripe_id(stripe_plan_id)
          next if plan.nil?

          discount_value = plan.price_in_cents * (discount.percent_off / 100.0) * period_in_months
        end
      # if there's a subscription event occurred within the period,
      # add it to correct event bracket.
      else
        # reject if the revenue event occurred after discount period ended
        next if last_subscription_event.created_at > discount.ended_at
        category = category_for_event(last_subscription_event)

        discount_value = last_subscription_event.amount * (discount.percent_off / 100.0) * period_in_months
      end

      # skip if the discount doesn't fit into a revenue category
      next if category.nil?

      increment(output[category], discount_value)
    end

    # TODO: Move out
    output[:total][:amount] = output[:starting][:amount] + output[:subscribed][:amount] - output[:canceled] [:amount] +
                              output[:upgraded][:amount] - output[:downgraded][:amount] +
                              output[:added] [:amount] - output[:expired][:amount]

    output[:total][:count] = output[:starting][:count] + output[:subscribed][:count] - output[:canceled] [:count] +
                             output[:added] [:count] - output[:expired][:count]

    output
  end

  def self.data_for_period(started, ended)
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

    active_discounts = self.active_in_period(started, ended)

    active_discounts.each do |discount|
      add_to_hash output, discount.revenue_discounts_for_period(started, ended)
    end
  end

  def self.subscription_events_before(date)
    RevenueEvent.where(event: SUBSCRIPTION_EVENTS).where('created_at <= ?', date).order(:created_at)
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
      Rails.logger.info revent
      nil
    end
  end
end
