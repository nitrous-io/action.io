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
    def do_request(params = {})
      get :pricing, params
    end

    context 'when not signed in' do
      before { do_request }

      it { should render_template 'pricing' }
      it { should respond_with :success }
    end

    context 'when signed in' do
      let(:user) { create :user }

      before do
        sign_in user
        do_request
      end

      it { should redirect_to "#{web_app_url}/#/n2o/upgrade" }
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
