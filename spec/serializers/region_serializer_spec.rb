require 'spec_helper'

describe RegionSerializer do
  let!(:region) { create :region }

  subject { region.serialize_as_json }

  it 'has only id, name, and description fields' do
    hash = JSON.parse(subject)['region']
    expect(hash.delete('id'         )).to eq(region.id)
    expect(hash.delete('name'       )).to eq(region.name)
    expect(hash.delete('description')).to eq(region.description)
    expect(hash.delete('state'      )).to eq(region.state)
    expect(hash.delete('ssl_enabled')).to eq(region.ssl_enabled)
    expect(hash).to be_empty
  end
end

