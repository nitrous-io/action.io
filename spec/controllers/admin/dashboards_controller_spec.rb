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
          expect assigns(:discounts_data)

          expect assigns(:starting_recurring_revenue)
          expect assigns(:ending_recurring_revenue)

          expect assigns(:starting_subscribers)
          expect assigns(:ending_subscribers)
        end

        it { should respond_with :success }
        it { should render_template 'mrr' }
      end

      context 'when request format is CSV' do
        it 'sets the downloadable filename using content-disposition header' do
          do_request format: 'csv', period_start: '2014-03-01', period_end: '2014-03-15'
          expect(response.header).to include("Content-Disposition" => "attachment; filename=\"mrr.csv\"")
        end
      end

      context 'start and end of reporting period' do

        context 'when no period_start param is given' do
          it 'assigns the beginning of the day 30 days ago to @period_start' do
            Timecop.freeze do
              do_request
              expect(assigns(:period_start)).to eq 30.days.ago.beginning_of_day
            end
          end
        end

        context 'when period_start param is not a valid date string' do
          it 'assigns the beginning of the day 30 days ago to @period_start' do
            Timecop.freeze do
              do_request period_start: 'not-a-date'
              expect(assigns(:period_start)).to eq 30.days.ago.beginning_of_day
            end
          end
        end

        context 'when a period_start param is given' do
          it 'assigns the beginning of the given day to @period_start' do
            do_request period_start: '2014-03-20'
            expect(assigns(:period_start)).to eq Date.new(2014, 3, 20)
          end
        end

        context 'when the period_start is later than the period_end' do
          it 'assigns the beginning of the day of the period_end to @period_start' do
            do_request period_start: '2014-03-20', period_end: '2014-03-01'
            expect(assigns(:period_start)).to eq Date.new(2014, 3, 01)
          end
        end

        context 'when no period_end param is given' do
          it 'assigns the end of the current day to @period_end' do
            Timecop.freeze do
              do_request
              expect(assigns(:period_end)).to eq Date.today.end_of_day
            end
          end
        end

        context 'when period_end param is not a valid date string' do
          it 'assigns the end of the current day to @period_end' do
            Timecop.freeze do
              do_request period_end: 'not-a-date'
              expect(assigns(:period_end)).to eq Date.today.end_of_day
            end
          end
        end

        context 'when a period_end param is given' do
          it 'assigns the beginning of the given day to @period_end' do
            do_request period_end: '2014-04-20'
            expect(assigns(:period_end)).to eq Date.new(2014, 4, 20).end_of_day
          end
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
