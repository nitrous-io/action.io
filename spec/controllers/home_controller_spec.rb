require 'spec_helper'

describe HomeController do
  describe 'GET index' do
    def do_request
      get :index
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

      it { should redirect_to console_url }
    end
  end

  describe 'GET ping' do
    before { get :ping }

    it { should respond_with :success }
    its('response.body') { should == 'PONG!' }
  end
end
