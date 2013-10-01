require 'spec_helper'

describe SubscriptionPlanSerializer do
  let!(:plan) { create :subscription_plan, highlight: true, display_order: 999, cpu_shared_multipler: 2, virtual_memory_multipler: 3, features: 'lol' }

  subject { plan.serialize_as_json }

  it 'has only id, name, and description fields' do
    hash = JSON.parse(subject)['subscription_plan']
    hash.delete('id'            ).should == plan.id
    hash.delete('name'          ).should == plan.name
    hash.delete('price'         ).should == plan.price
    hash.delete('interval'      ).should == plan.interval
    hash.delete('features'      ).should == plan.features
    hash.delete('highlight'     ).should == plan.highlight
    hash.delete('display_order' ).should == plan.display_order
    hash.delete('n2o_amount'    ).should == plan.n2o_amount
    hash.delete('cpu_shares_multiplier').should == plan.cpu_shares_multiplier
    hash.delete('virtual_memory_multiplier').should == plan.virtual_memory_multiplier
    hash.should be_empty
  end
end
