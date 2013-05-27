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

      context 'with ref=#{referral_code}' do
        let!(:referring_invite) { FactoryGirl.create(:invite, referral_code: 'random_referral_code') }

        it 'should increment the referred_visits attribute of the referring invite by 1' do
          expect {
            do_request(ref: 'random_referral_code')
          }.to change { referring_invite.reload.referred_visits }.by(1)
        end
      end
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
    it { should redirect_to 'https://www.hipchat.com/gqRzb6GdX' }
  end

  describe 'GET pricing' do
    before do
      create :plan
      create :plan, active: false
      get :pricing
    end

    it do
      should respond_with :success
      should render_template 'pricing'
      plans.map(&:active).uniq.should eq([true])
    end
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
end
