require 'spec_helper'

describe BoxhostSerializer do
  let!(:boxhost) { create :boxhost }

  subject { boxhost.serialize_as_json }

  it 'has the fields we expect it to have' do
    hash = JSON.parse(subject)['boxhost']
    expect(hash.delete('id')).to eq boxhost.id
    expect(hash.delete('name')).to eq boxhost.name
    expect(hash.delete('state')).to eq boxhost.state
    expect(hash.delete('dedicated')).to eq boxhost.dedicated
    expect(hash.delete('owner_id')).to eq boxhost.owner_id
    expect(hash.delete('location_id')).to eq boxhost.location_id
    expect(hash.delete('boxhost_plan_id')).to eq boxhost.boxhost_plan_id
    expect(hash).to be_empty
  end
end
