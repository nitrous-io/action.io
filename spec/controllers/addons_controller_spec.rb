require 'spec_helper'

describe AddonsController do
  let!(:user) { create :user }
  describe 'GET index' do
    let!(:addon1) { create :addon }
    let!(:addon2) { create :addon }

    def do_request
      get :index, format: 'json'
    end

    context 'when signed in' do
      before { sign_in user }

      it 'returns a list of addons' do
        do_request
        response.should be_success
        assigns(:addons).should =~ [addon1, addon2]
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
