require 'spec_helper'

describe SubscriptionSerializer do
  let!(:plan) { create :plan }
  let!(:subscription) { create :subscription, plan: plan }

  subject { subscription.serialize_as_json }

  it 'has only state, plan' do
    hash = JSON.parse(subject)['subscription']
    hash.delete('state').should == subscription.state
    hash.delete('plan').should == JSON.parse(plan.serialize_as_json)['plan']
    hash.should be_empty
  end
end
