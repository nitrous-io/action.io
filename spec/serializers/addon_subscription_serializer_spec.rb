require 'spec_helper'

describe AddonSubscriptionSerializer do
  let!(:subscription)  { create :addon_subscription, env_vars: { "hello" => "world" }.to_json }

  subject { subscription.serialize_as_json }

  it 'has only id and uid as part of the attributes' do
    hash = JSON.parse(subject)['addon_subscription']
    hash.delete('id').should == subscription.id
    hash.delete('addon_plan_id').should == subscription.addon_plan_id
    hash.delete('box_id').should == subscription.box_id
    hash.delete('state').should == subscription.state
    hash.delete('env_vars').should == JSON.parse(subscription.env_vars)
    hash.should be_empty
  end
end


