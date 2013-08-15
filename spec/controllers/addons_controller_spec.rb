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

  describe 'GET show' do
    let!(:addon1) { create :addon, state: "enabled" }
    let!(:addon2) { create :addon }

    def do_request(id=addon1.uid)
      get :show, id: id, format: 'json'
    end

    it 'shows the addons' do
      do_request
      response.should be_success
      assigns(:addon).should eq(addon1)
    end

    it "does not show the un-enabled addon" do
      expect {
        do_request addon2.uid
      }.to raise_error
    end
  end
end
