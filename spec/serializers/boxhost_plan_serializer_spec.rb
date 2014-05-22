require 'spec_helper'

describe BoxhostPlanSerializer do
  let!(:boxhost_plan) { create :boxhost_plan }

  subject { boxhost_plan.serialize_as_json }

  it 'has fields we expect it to have' do
    hash = JSON.parse(subject)['boxhost_plan']
    expect(hash.delete('id')).to eq boxhost_plan.id
    expect(hash.delete('name')).to eq boxhost_plan.name
    expect(hash.delete('price')).to eq boxhost_plan.price
    expect(hash.delete('interval')).to eq boxhost_plan.interval
    expect(hash.delete('memory')).to eq boxhost_plan.memory
    expect(hash.delete('storage')).to eq boxhost_plan.storage
    expect(hash.delete('box_limit')).to eq boxhost_plan.box_limit
    expect(hash.delete('display_order')).to eq boxhost_plan.display_order
    expect(hash.delete('features')).to eq boxhost_plan.features
    expect(hash).to be_empty
  end
end
