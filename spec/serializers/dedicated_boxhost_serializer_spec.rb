require 'spec_helper'

describe DedicatedBoxhostSerializer do
  let!(:boxhost) { create :dedicated_boxhost }

  subject { boxhost.serialize_as_json }

  it 'has the fields we expect it to have' do
    hash = JSON.parse(subject)['dedicated_boxhost']
    expect(hash.delete('id')).to eq boxhost.id
    expect(hash.delete('name')).to eq boxhost.name
    expect(hash.delete('state')).to eq boxhost.state
    expect(hash.delete('dedicated')).to eq boxhost.dedicated?
    expect(hash.delete('owner_id')).to eq boxhost.owner_id
    expect(hash.delete('region_id')).to eq boxhost.region_id
    expect(hash.delete('boxhost_plan_id')).to eq boxhost.boxhost_plan_id
    expect(hash).to be_empty
  end
end
