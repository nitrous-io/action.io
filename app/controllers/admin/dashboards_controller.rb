class Admin::DashboardsController < AdminController
  layout 'dashboard'
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
    set_period_start_and_end

    # FIXME: Optimize the database queries in FUTURE.
    # discussion: https://github.com/nitrous-io/action.io/pull/546#discussion-diff-10949907

    #individual plans
    @start_plan_id = Plan.find_by_name('Start').id
    @shift_plan_id = Plan.find_by_name('Shift').id
    @turbo_plan_id = Plan.find_by_name('Turbo').id
    @nitro_plan_id = Plan.find_by_name('Nitro').id

    #team plans
    @small_plan_id = Plan.find_by_name('Small').id
    @medium_plan_id = Plan.find_by_name('Medium').id
    @large_plan_id = Plan.find_by_name('Large').id

    @start_plans_count = subscriptions_count(@start_plan_id)
    @shift_plans_count = subscriptions_count(@shift_plan_id)
    @turbo_plans_count = subscriptions_count(@turbo_plan_id)
    @nitro_plans_count = subscriptions_count(@nitro_plan_id)

    @small_plans_count = subscriptions_count(@small_plan_id)
    @medium_plans_count = subscriptions_count(@meidum_plan_id)
    @large_plans_count = subscriptions_count(@large_plan_id)
  end

  private
  def set_period_start_and_end
    if params[:period_start] && params[:period_end]
      @period_start = Date.parse params[:period_start]
      @period_end = Date.parse params[:period_end]
    else
      @period_start = Date.today.beginning_of_month
      @period_end = Date.today
    end
  end

  def subscriptions_count(plan_id)
    Subscription.where("plan_id = ? AND created_at >= ? and created_at <= ?", plan_id, @period_start, @period_end).count
  end
end
