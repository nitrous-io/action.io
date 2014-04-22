class RevenueEvent < ActiveRecord::Base
  SUBSCRIBED = 0
  UPGRADED = 1
  DOWNGRADED = 2
  CANCELED = 3
  BILLED = 4
  CHARGED = 5
  REFUNDED = 6

  START_OF_BILLING = Date.new(2013, 11, 1) # Nitrous.IO enabled billing in November 2013.

  attr_accessible :event, :amount, :created_at, :stripe_id, :subscription_started_at

  validate :validate_presence_of_stripe_data

  scope :subscribed, -> { where(event: SUBSCRIBED) }
  scope :upgraded,   -> { where(event: UPGRADED) }
  scope :downgraded, -> { where(event: DOWNGRADED) }
  scope :canceled,   -> { where(event: CANCELED) }
  scope :billed,     -> { where(event: BILLED) }
  scope :charged,    -> { where(event: CHARGED) }
  scope :refunded,   -> { where(event: REFUNDED) }

  scope :in_period,  -> (period_start, period_end) do
    where("created_at >= ? AND created_at <= ?", period_start.beginning_of_day, period_end.end_of_day)
  end

  def self.recurring_revenue_for_period(period_start, period_end)
    in_period = self.in_period(period_start, period_end)

    subscribed_amount = in_period.subscribed.sum('amount')
    upgraded_amount = in_period.upgraded.sum('amount')
    downgraded_amount = in_period.downgraded.sum('amount')
    canceled_amount = in_period.canceled.sum('amount')

    subscribed_amount + upgraded_amount - downgraded_amount - canceled_amount
  end

  def self.subscribers_for_period(period_start, period_end)
    in_period = self.in_period(period_start, period_end)

    subscribed_count = in_period.subscribed.count
    canceled_count = in_period.canceled.count

    subscribed_count - canceled_count
  end

  # Returns the total number of subscribers for the plan with the given
  # stripe_plan_id on the given day.
  def self.total_subscribers_for_plan(stripe_plan_id, day)
    period = self.in_period(START_OF_BILLING, day.end_of_day)

    subscribed_count = period.subscribed.where(stripe_plan_id: stripe_plan_id).count
    canceled_count = period.canceled.where(stripe_plan_id: stripe_plan_id).count

    subscribed_count - canceled_count
  end

  def self.stripe_plan_ids
    self.select(:stripe_plan_id).distinct.pluck(:stripe_plan_id).compact
  end

  def self.billed_in_period(period_start, period_end)
    in_period = self.in_period(period_start, period_end)
    in_period.billed.sum('amount')
  end

  def self.collected_in_period(period_start, period_end)
    in_period = self.in_period(period_start, period_end)
    charged = in_period.charged.sum('amount')
    refunded = in_period.refunded.sum('amount')
    charged - refunded
  end

  def self.event_data_for_period(event, period_start, period_end)
    event_records = in_period(period_start, period_end).send(event)
    event_amount = event_records.sum("amount")
    event_count = event_records.count
    if event_count > 0
      event_avg = event_amount / event_count
    else
      event_avg = 0
    end

    { amount: event_amount, count: event_count, avg: event_avg }
  end

  def self.export_to_csv(unit, period_start, period_end)
    CSV.generate do |csv|
      csv << [ "Period", 'Starting MRR', 'Upgrades', 'Downgrades', 'Churn', 'New Subscriptions', 'Ending MRR (Committed)', 'Total Billed (Invoiced)', 'Total Collected' ]

      add_record = lambda do |record_start_date|
        if unit == 'weekly'
          record_start_date = record_start_date.beginning_of_week(start_day = :sunday)
          record_end_date = record_start_date.advance(weeks: 1) - 1
        else
          record_start_date = record_start_date.beginning_of_month
          record_end_date = record_start_date.advance(months: 1) - 1
        end

        subscribed_data = RevenueEvent.event_data_for_period "subscribed", record_start_date, record_end_date
        upgraded_data = RevenueEvent.event_data_for_period "upgraded",  record_start_date, record_end_date
        downgraded_data = RevenueEvent.event_data_for_period "downgraded", record_start_date, record_end_date
        canceled_data = RevenueEvent.event_data_for_period "canceled", record_start_date, record_end_date

        starting_recurring_revenue = RevenueEvent.recurring_revenue_for_period(START_OF_BILLING, record_start_date - 1)
        ending_recurring_revenue = RevenueEvent.recurring_revenue_for_period(START_OF_BILLING, record_end_date)

        billed_in_period = RevenueEvent.billed_in_period record_start_date, record_end_date
        collected_in_period = RevenueEvent.collected_in_period record_start_date, record_end_date

        csv << [
          "#{record_start_date} - #{record_end_date}",
          starting_recurring_revenue / 100.0,
          upgraded_data[:amount] / 100.0,
          downgraded_data[:amount] / 100.0,
          canceled_data[:amount] / 100.0,
          subscribed_data[:amount] / 100.0,
          ending_recurring_revenue / 100.0,
          billed_in_period / 100.0,
          collected_in_period / 100.0
        ]

        add_record.call(record_end_date + 1) if record_end_date <= period_end
      end

      add_record.call(period_start)
    end
  end

  # Stripe charges 2.9% + 30c for every successful charge.
  # And refunds that fee for every refund.
  # https://stripe.com/us/pricing
  # Calculation is based on the Stripe charges as of 27 March 2014.
  STRIPE_BASE_CHARGE = 30
  STRIPE_PERCENTAGE_CHARGE = 2.9

  def self.calculate_stripe_fees(charged_amount, charged_count, refunded_amount, refunded_count)
    fixed_cost = (charged_count * STRIPE_BASE_CHARGE) - (refunded_count * STRIPE_BASE_CHARGE)
    charged_percentage_cost = (charged_amount * STRIPE_PERCENTAGE_CHARGE)  / 100
    refunded_percentage_cost = (refunded_amount * STRIPE_PERCENTAGE_CHARGE) / 100
    fixed_cost + charged_percentage_cost - refunded_percentage_cost
  end

  private
  def validate_presence_of_stripe_data
    return if ![SUBSCRIBED, CANCELED, UPGRADED, DOWNGRADED].include?(self.event)

    if self.stripe_customer_id.blank?
      self.errors.add :stripe_customer_id, "can't be blank"
    end
    if self.stripe_plan_id.blank?
      self.errors.add :stripe_plan_id, "can't be blank"
    end
  end
end
