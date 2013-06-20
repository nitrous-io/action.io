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
    it { should redirect_to 'https://www.hipchat.com/gqRzb6GdX' }
  end

  describe 'GET pricing' do
    before { get :pricing }

    it { should respond_with :success }
    it { should render_template 'pricing' }
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

  describe "GET join" do
    context "with ref" do
      before { get :join, ref: 'abcref' }

      it { should redirect_to new_user_registration_url(ref: 'abcref') }
    end

    context "without ref" do
      before { get :join }

      it { should redirect_to new_user_registration_url }
    end
  end
end
