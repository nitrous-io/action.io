require 'spec_helper'

describe HomeController do
  describe 'GET index' do
    def do_request(params = {})
      get :index, params
    end

    context 'when not signed in' do
      before { do_request }

      it { should render_template 'index' }
      it { should respond_with :success }
    end

    context 'when signed in' do
      let(:user) { create :user }

      before do
        sign_in user
        do_request
      end

      it { should redirect_to web_app_url }
    end
  end

  describe 'GET ping' do
    before { get :ping }

    it { should respond_with :success }
    its('response.body') { should == 'PONG!' }
  end

  describe 'GET chat' do
    before { get :chat }

    it { should respond_with :redirect }
    it { should redirect_to 'https://www.hipchat.com/gkbrGh4Bi' }
  end

  describe 'GET pricing' do
    before do
      KeyValue.create key: N2oAllocation::N2O_128MB_MEMORY,  value: 40
      KeyValue.create key: N2oAllocation::N2O_250MB_STORAGE, value: 10
      KeyValue.create key: N2oFill::N2O_SIGN_UP_BONUS, value: 155
      KeyValue.create key: AIO::N2O_PRICE_CENTS, value: 7
      get :pricing
    end

    it { should respond_with :success }
    it { should render_template 'pricing' }

    it 'sets ivars for the view' do
      expect(assigns :n2o_128mb_memory).to eq 40
      expect(assigns :n2o_250mb_storage).to eq 10
      expect(assigns :n2o_price_cents).to eq 7
      expect(assigns :free_n2o).to eq 155
    end
  end

  describe 'GET business' do
    before { get :business }

    it { should respond_with :success }
    it { should render_template 'business' }
  end

  describe 'GET collab' do
    before { get :collab }

    it { should respond_with :success }
    it { should render_template 'collab' }
  end

  describe 'GET jobs' do
    before { get :jobs }

    it { should respond_with :success }
    it { should render_template 'jobs' }
  end

  describe 'GET team' do
    before { get :team }

    it { should respond_with :success }
    it { should render_template 'team' }
  end

  describe 'GET about' do
    before { get :about }

    it { should respond_with :success }
    it { should render_template 'about' }
  end
end
