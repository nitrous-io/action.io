require 'spec_helper'

describe RegionsController do
  describe 'GET index' do
    let!(:region1) { create :region, enabled: true }
    let!(:region2) { create :region, enabled: true }
    let!(:region3) { create :region }

    before { get :index, format: 'json' }

    it { should respond_with :success }

    it "returns the list of regions in json" do
      assigns(:regions).should == [region1, region2]
      response.body.should == { regions: assigns(:regions).serialize_as_hash }.to_json
    end
  end
end

