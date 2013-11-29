require 'spec_helper'

describe PlanSerializer do
  let!(:plan) { create :plan, highlight: true, display_order: 999, cpu_multiplier: 2, vmem_multiplier: 3, features: 'lol' }

  subject { plan.serialize_as_json }

  it 'has only id, name, and description fields' do
    hash = JSON.parse(subject)['plan']
    hash.delete('id'            ).should == plan.id
    hash.delete('name'          ).should == plan.name
    hash.delete('price'         ).should == plan.price
    hash.delete('interval'      ).should == plan.interval
    hash.delete('features'      ).should == plan.features
    hash.delete('highlight'     ).should == plan.highlight
    hash.delete('display_order' ).should == plan.display_order
    hash.delete('n2o_amount'    ).should == plan.n2o_amount
    hash.delete('cpu_multiplier').should == plan.cpu_multiplier
    hash.delete('vmem_multiplier').should == plan.vmem_multiplier
    hash.should be_empty
  end
end
