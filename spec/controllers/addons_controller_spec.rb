require 'spec_helper'

describe AddonsController do
  let!(:user) { create :user }
  let!(:addon) { create :addon }

  describe 'GET index' do
    let!(:addon2) { create :addon, state: "enabled" }

    def do_request
      get :index, format: 'json'
    end

    context 'when signed in' do
      before { sign_in user }

      it 'returns a list of addons' do
        do_request
        response.should be_success
        assigns(:addons).should =~ [addon, addon2]
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
