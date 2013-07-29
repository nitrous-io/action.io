require 'spec_helper'

describe AddonSubscriptionSerializer do
  let!(:subscription)  { create :addon_subscription }

  subject { subscription.serialize_as_json }

  it 'has only id and uid as part of the attributes' do
    hash = JSON.parse(subject)['addon_subscription']
    hash.delete('id').should == subscription.id
    hash.delete('addon_id').should == subscription.addon_id
    hash.delete('box_id').should == subscription.box_id
    hash.delete('state').should == subscription.state
    hash.should be_empty
  end
end


