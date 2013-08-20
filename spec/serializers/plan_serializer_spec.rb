require 'spec_helper'

describe PlanSerializer do
  let!(:plan) { create :plan }

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
    hash.should be_empty
  end
end

