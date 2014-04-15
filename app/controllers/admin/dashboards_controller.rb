class Admin::DashboardsController < AdminController
  respond_to :html

  def index
  end

  def mrr
    @start_of_billing = Date.new(2013, 11, 1) # Nitrous.IO enabled billing in November 2013.
    set_period_start_and_end

    respond_to do |format|
      format.html do
        @subscribed_data = RevenueEvent.event_data_for_period "subscribed", @period_start, @period_end
        @upgraded_data = RevenueEvent.event_data_for_period "upgraded", @period_start, @period_end
        @downgraded_data = RevenueEvent.event_data_for_period "downgraded", @period_start, @period_end
        @canceled_data = RevenueEvent.event_data_for_period "canceled", @period_start, @period_end

        @starting_recurring_revenue = RevenueEvent.recurring_revenue_for_period(@start_of_billing, @period_start - 1)
        @ending_recurring_revenue = RevenueEvent.recurring_revenue_for_period(@start_of_billing, @period_end)

        @starting_subscribers = RevenueEvent.subscribers_for_period(@start_of_billing, @period_start - 1)
        @ending_subscribers = RevenueEvent.subscribers_for_period(@start_of_billing, @period_end)

        @billed_in_period = RevenueEvent.billed_in_period(@period_start, @period_end)
        @collected_in_period = RevenueEvent.collected_in_period(@period_start, @period_end)
      end

      format.csv do
        @unit = params[:unit] || 'monthly'
        csv_output = RevenueEvent.export_to_csv(@unit, @period_start, @period_end)

        response.headers['Content-Disposition'] = "attachment; filename=\"mrr_#{@unit}.csv\""
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
    if params[:day].present?
      @day = Date.parse(params[:day])
    else
      @day = Date.today
    end

    stripe_plan_ids = RevenueEvent.stripe_plan_ids
    current_plans = Plan.where(stripe_id: stripe_plan_ids).order(:price)
    archived_plans = stripe_plan_ids - current_plans.map(&:stripe_id)

    @current_plans_table = Hash[current_plans.map { |plan| [plan, RevenueEvent.total_subscribers_for_plan(plan.stripe_id, @day)] }]
    @archived_plans_table = Hash[archived_plans.map { |plan| [plan, RevenueEvent.total_subscribers_for_plan(plan, @day)] }]
  end

  private
  def set_period_start_and_end
    if params[:period_start] && params[:period_end]
      @period_start = Date.parse(params[:period_start]).beginning_of_day
      @period_end = Date.parse(params[:period_end]).end_of_day
    else
      @period_start = Date.today.beginning_of_month
      @period_end = Date.today
    end
  end
end
