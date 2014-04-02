require 'spec_helper'

describe Admin::DashboardsController do
  let!(:admin) { create :admin }

  before do
    sign_in admin
    basic_auth 'admin', 'admin'
  end

  describe 'GET index' do
    def do_request(params={})
      get :index, params
    end

    context 'when signed in' do
      before { do_request }
      it { should respond_with :success }
      it { should render_template 'index' }
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'GET mrr' do
    def do_request(params={})
      get :mrr, params
    end

    context 'when signed in' do
      context 'when request format is html' do
        before { do_request }

        it 'assigns all required data for the given period' do
          expect assigns(:subscribed_data)
          expect assigns(:upgraded_data)
          expect assigns(:downgraded_data)
          expect assigns(:canceled_data)

          expect assigns(:starting_recurring_revenue)
          expect assigns(:ending_recurring_revenue)

          expect assigns(:billed_in_period)
          expect assigns(:collected_in_period)
        end

        it { should respond_with :success }
        it { should render_template 'mrr' }
      end

      context 'when request format is CSV' do
        it 'calls export_to_csv with unit, period start and period end' do
          expect(RevenueEvent).to receive(:export_to_csv).with 'weekly', Date.parse("2014-03-01").beginning_of_day, Date.parse("2014-03-15").end_of_day
          do_request format: 'csv', unit: 'weekly', period_start: '2014-03-01', period_end: '2014-03-15'
        end

        it 'sets the downloadable filename using content-disposition header' do
          do_request format: 'csv', unit: 'weekly', period_start: '2014-03-01', period_end: '2014-03-15'
          expect(response.header).to include("Content-Disposition" => "attachment; filename=\"mrr_weekly.csv\"")
        end
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'GET cashflow' do
    def do_request(params={})
      get :cashflow, params
    end

    context 'when signed in' do
      before { do_request }
      it { should respond_with :success }
      it { should render_template 'cashflow' }
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'GET plans' do
    let!(:start) { create :plan, name: 'Start' }
    let!(:shift) { create :plan, name: 'Shift' }
    let!(:turbo) { create :plan, name: 'Turbo' }
    let!(:nitro) { create :plan, name: 'Nitro' }
    let!(:small) { create :plan, name: 'Small' }
    let!(:medium) { create :plan, name: 'Medium' }
    let!(:large) { create :plan, name: 'Large' }

    def do_request(params={})
      get :plans, { period_start: '2014-03-01', period_end: '2014-03-31' }.merge(params)
    end

    context 'when signed in' do
      before do
        create :subscription, plan: start, state: 'active', created_at: Time.new(2014, 3, 10)
        create :subscription, plan: start, state: 'delinquent', created_at: Time.new(2014, 3, 15)
        create :subscription, plan: start, state: 'pending', created_at: Time.new(2014, 3, 15)

        # some edge cases to test period boundaries
        create :subscription, plan: start, state: 'active', created_at: Time.new(2014, 2, 28)
        create :subscription, plan: start, state: 'active', created_at: Time.new(2014, 4, 1)
        create :subscription, plan: start, state: 'active', created_at: Time.new(2014, 3, 1, 0, 0, 0)
        create :subscription, plan: start, state: 'active', created_at: Time.new(2014, 3, 31, 23, 59, 59)

        create :subscription, plan: shift, state: 'active', created_at: Time.new(2014, 3, 10)
        create :subscription, plan: shift, state: 'delinquent', created_at: Time.new(2014, 3, 10)
        create :subscription, plan: shift, state: 'pending', created_at: Time.new(2014, 3, 10)
        create :subscription, plan: shift, state: 'canceled', created_at: Time.new(2014, 3, 10)

        create :subscription, plan: turbo, state: 'active', created_at: Time.new(2014, 3, 10)
        create :subscription, plan: turbo, state: 'delinquent', created_at: Time.new(2014, 3, 10)
        create :subscription, plan: turbo, state: 'pending', created_at: Time.new(2014, 3, 10)
        create :subscription, plan: turbo, state: 'canceled', created_at: Time.new(2014, 3, 10)

        create :subscription, plan: nitro, state: 'active', created_at: Time.new(2014, 3, 10)
        create :subscription, plan: nitro, state: 'delinquent', created_at: Time.new(2014, 3, 10)
        create :subscription, plan: nitro, state: 'pending', created_at: Time.new(2014, 3, 10)
        create :subscription, plan: nitro, state: 'canceled', created_at: Time.new(2014, 3, 10)

        create :subscription, plan: small, state: 'active', created_at: Time.new(2014, 3, 10)
        create :subscription, plan: small, state: 'delinquent', created_at: Time.new(2014, 3, 10)
        create :subscription, plan: small, state: 'pending', created_at: Time.new(2014, 3, 10)
        create :subscription, plan: small, state: 'canceled', created_at: Time.new(2014, 3, 10)

        create :subscription, plan: medium, state: 'active', created_at: Time.new(2014, 3, 10)
        create :subscription, plan: medium, state: 'delinquent', created_at: Time.new(2014, 3, 10)
        create :subscription, plan: medium, state: 'pending', created_at: Time.new(2014, 3, 10)
        create :subscription, plan: medium, state: 'canceled', created_at: Time.new(2014, 3, 10)

        create :subscription, plan: large, state: 'active', created_at: Time.new(2014, 3, 10)
        create :subscription, plan: large, state: 'delinquent', created_at: Time.new(2014, 3, 10)
        create :subscription, plan: large, state: 'pending', created_at: Time.new(2014, 3, 10)
        create :subscription, plan: large, state: 'canceled', created_at: Time.new(2014, 3, 10)

        do_request
      end

      it 'should count only the number of unchurned subscriptions per plan' do
        expect(assigns(:start_plans_count)).to eq(4)
        expect(assigns(:shift_plans_count)).to eq(2)
        expect(assigns(:turbo_plans_count)).to eq(2)
        expect(assigns(:nitro_plans_count)).to eq(2)

        expect(assigns(:small_plans_count)).to eq(2)
        expect(assigns(:medium_plans_count)).to eq(2)
        expect(assigns(:large_plans_count)).to eq(2)
      end

      it { should respond_with :success }
      it { should render_template 'plans' }
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

  describe 'GET churned_in_period' do
    def do_request(params={})
      get :churned_in_period, { period_start: '2014-03-01', period_end: '2014-03-31' }.merge(params)
    end

    context 'when signed in' do
      before { do_request }

      it { should respond_with :success }
      it { should render_template 'churned_in_period' }
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

end
