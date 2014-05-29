require 'spec_helper'

describe PlanSerializer do
  let!(:plan) { create :plan, highlight: true, display_order: 999, cpu_multiplier: 2, vmem_multiplier: 3, features: ['lol'] }

  subject { plan.serialize_as_json }

  it 'has only id, name, and description fields' do
    hash = JSON.parse(subject)['plan']
    expect(hash.delete('id'            )).to eq(plan.id)
    expect(hash.delete('name'          )).to eq(plan.name)
    expect(hash.delete('price'         )).to eq(plan.price)
    expect(hash.delete('interval'      )).to eq(plan.interval)
    expect(hash.delete('features'      )).to eq(plan.features)
    expect(hash.delete('highlight'     )).to eq(plan.highlight)
    expect(hash.delete('display_order' )).to eq(plan.display_order)
    expect(hash.delete('n2o_amount'    )).to eq(plan.n2o_amount)
    expect(hash.delete('cpu_multiplier')).to eq(plan.cpu_multiplier)
    expect(hash.delete('vmem_multiplier')).to eq(plan.vmem_multiplier)
    expect(hash.delete('memory'        )).to eq(plan.memory)
    expect(hash.delete('storage'       )).to eq(plan.storage)
    expect(hash.delete('trial_months'  )).to eq(plan.trial_months)
    expect(hash.delete('box_limit'  )).to eq(plan.box_limit)
    expect(hash).to be_empty
  end
end
