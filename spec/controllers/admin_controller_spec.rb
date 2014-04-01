require 'spec_helper'

describe AdminController do
  let!(:user)  { create :user }
  let!(:admin) { create :admin }

  before do
    sign_in admin
    basic_auth 'admin', 'admin'
  end

  describe 'GET index' do
    def do_request(params = {})
      get :index, params
    end

    context 'when signed in as admin' do
      context 'when page is requested without any user identifier' do
        before { do_request }
        it { should respond_with :success }
        it { should render_template 'index' }
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
    it_behaves_like 'an action that returns 401 when not authenticated with basic auth credentials'
  end
end

