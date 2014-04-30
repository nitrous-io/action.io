class Admin::DashboardsController < AdminController
  include ReceiptHelper # to get the `as_currency` helper
  respond_to :html

  def index
  end

  def mrr
    @start_of_billing = RevenueEvent::START_OF_BILLING
    set_period_start_and_end

    @subscribed_data = RevenueEvent.event_data_for_period "subscribed", @period_start, @period_end
    @upgraded_data = RevenueEvent.event_data_for_period "upgraded", @period_start, @period_end
    @downgraded_data = RevenueEvent.event_data_for_period "downgraded", @period_start, @period_end
    @canceled_data = RevenueEvent.event_data_for_period "canceled", @period_start, @period_end

    @discounts_data = AppliedDiscount.data_for_period @period_start, @period_end

    @starting_recurring_revenue = RevenueEvent.recurring_revenue_for_period(@start_of_billing, @period_start - 1)
    @ending_recurring_revenue = RevenueEvent.recurring_revenue_for_period(@start_of_billing, @period_end)

    @starting_subscribers = RevenueEvent.subscribers_for_period(@start_of_billing, @period_start - 1)
    @ending_subscribers = RevenueEvent.subscribers_for_period(@start_of_billing, @period_end)

    respond_to do |format|
      format.html

      format.csv do
        csv_output = CSV.generate do |csv|
          csv << [ 'Starting MRR', 'New Subscriptions', 'Upgrades', 'Downgrades', 'Cancelations', 'Added Discounts', 'Expired Discounts', 'Ending MRR', 'Starting Subscribers', 'Cancellled Subscribers', 'Ending Subscribers']
          csv << [ as_currency(@starting_recurring_revenue - @discounts_data[:starting][:amount]),
                   as_currency(@subscribed_data[:amount] - @discounts_data[:subscribed][:amount]),
                   as_currency(@upgraded_data[:amount] - @discounts_data[:upgraded][:amount]),
                   as_currency(@downgraded_data[:amount] - @discounts_data[:downgraded][:amount]),
                   as_currency(@canceled_data[:amount] - @discounts_data[:canceled][:amount]),
                   as_currency(@discounts_data[:expired][:amount]),
                   as_currency(@discounts_data[:canceled][:amount]),
                   as_currency(@ending_recurring_revenue - @discounts_data[:total][:amount]),
                   @starting_subscribers,
                   @canceled_data[:count],
                   @ending_subscribers
                 ]
        end

        response.headers['Content-Disposition'] = 'attachment; filename="mrr.csv"'
        render text: csv_output
      end
    end
  end

  def cashflow
    set_period_start_and_end

    revenue_events_in_period = RevenueEvent.in_period @period_start, @period_end

    @charged_amount = revenue_events_in_period.charged.sum('amount')
    @charged_count = revenue_events_in_period.charged.count

    @refunded_amount = revenue_events_in_period.refunded.sum('amount')
    @refunded_count = revenue_events_in_period.refunded.count

    @gross_earnings_for_period = @charged_amount - @refunded_amount
    @stripe_fees_for_period = RevenueEvent.calculate_stripe_fees @charged_amount, @charged_count, @refunded_amount, @refunded_count
    @net_earnings_for_period = @gross_earnings_for_period - @stripe_fees_for_period
  end

  def plans
    @day = parse_date(params[:day]) || Date.today

    stripe_plan_ids = RevenueEvent.stripe_plan_ids
    current_plans = Plan.where(stripe_id: stripe_plan_ids).order(:price)
    archived_plans = stripe_plan_ids - current_plans.map(&:stripe_id)

    @current_plans_table = Hash[current_plans.map { |plan| [plan, RevenueEvent.total_subscribers_for_plan(plan.stripe_id, @day)] }]
    @archived_plans_table = Hash[archived_plans.map { |plan| [plan, RevenueEvent.total_subscribers_for_plan(plan, @day)] }]
  end

  private
  def set_period_start_and_end
    @period_start = (parse_date(params[:period_start]) || 30.days.ago).beginning_of_day
    @period_end = (parse_date(params[:period_end]) || Date.today).end_of_day

    if @period_start > @period_end
      @period_start = @period_end.beginning_of_day
    end
  end

  def parse_date(param)
    param.to_s.to_date
  rescue ArgumentError
    nil
  end
end
