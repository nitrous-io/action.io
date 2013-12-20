require 'spec_helper'

describe SubscriptionSerializer do
  let!(:subscription) { create :subscription }
  subject { subscription.serialize_as_json }

  it 'has only state, plan' do
    hash = JSON.parse(subject)['subscription']
    expect(hash.delete('state')).to eq(subscription.state)
    expect(hash.delete('plan_id')).to eq(subscription.plan_id)
    expect(hash).to be_empty
  end
end
