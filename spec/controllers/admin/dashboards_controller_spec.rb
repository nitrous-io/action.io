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

          expect assigns(:starting_subscribers)
          expect assigns(:ending_subscribers)

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
    def do_request(params={})
      get :plans, params
    end

    context 'when signed in' do
      context 'when no day param is given' do
        it 'assigns the current day to @day' do
          Timecop.freeze do
            do_request
            expect(assigns(:day)).to eq Date.today
          end
        end
      end

      context 'when day param is not a valid date string' do
        it 'assigns the current day to @day' do
          Timecop.freeze do
            do_request day: 'not-a-date'
            expect(assigns(:day)).to eq Date.today
          end
        end
      end

      context 'when a day param is given' do
        it 'assigns the day param to @day' do
          do_request day: '2014-03-01'
          expect(assigns(:day)).to eq Date.new(2014, 3, 1)
        end
      end

      context do
        before { do_request }

        it { should respond_with :success }
        it { should render_template 'plans' }
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end

end
