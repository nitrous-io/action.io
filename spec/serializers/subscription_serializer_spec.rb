require 'spec_helper'

describe SubscriptionSerializer do
  let!(:subscription) { create :subscription }
  subject { subscription.serialize_as_json }

  it 'has only state, plan' do
    hash = JSON.parse(subject)['subscription']
    hash.delete('state').should == subscription.state
    hash.delete('plan_id').should == subscription.plan_id
    hash.should be_empty
  end
end
