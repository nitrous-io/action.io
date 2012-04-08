require 'spec_helper'

describe ConsoleController do
  let(:user) { create :user }

  describe 'GET index' do
    def do_request
      get :index
    end

    context 'when logged in' do
      before do
        sign_in user
        do_request
      end

      it { should render_template 'index' }
      it { should respond_with :success }
    end

    it_behaves_like 'an action that requires sign in'
  end
end
