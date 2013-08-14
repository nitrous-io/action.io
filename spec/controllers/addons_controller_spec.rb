require 'spec_helper'

describe AddonsController do

  describe 'GET index' do
    let!(:addon1) { create :addon }
    let!(:addon2) { create :addon, state: "enabled" }
    let!(:addon3) { create :addon, state: "enabled" }

    def do_request
      get :index, format: 'json'
    end

    it 'returns a list of addons' do
      do_request
      response.should be_success
      addons = assigns(:addons)
      addons.should =~ [addon2, addon3]
    end
  end
end
