require 'spec_helper'

describe SubscriptionSerializer do
  let!(:subscription_plan) { create :subscription_plan }
  let!(:subscription) { create :subscription, subscription_plan: subscription_plan }

  subject { subscription.serialize_as_json }

  it 'has only state, subscription_plan' do
    hash = JSON.parse(subject)['subscription']
    hash.delete('state'            ).should == subscription.state
    hash.delete('subscription_plan').should == JSON.parse(subscription_plan.serialize_as_json)['subscription_plan']
    hash.should be_empty
  end
end
