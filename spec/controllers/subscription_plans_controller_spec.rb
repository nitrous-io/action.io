require 'spec_helper'

describe SubscriptionPlansController do
  describe 'GET index' do
    let!(:plan1) { create :plan }
    let!(:plan2) { create :plan }

    before { get :index, format: 'json' }

    it { should respond_with :success }

    it "returns the list of plans in json" do
      assigns(:plans).should == [plan1, plan2]
      response.body.should == { plans: assigns(:plans).serialize_as_hash }.to_json
    end
  end
end

