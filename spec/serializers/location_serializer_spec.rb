require 'spec_helper'

describe LocationSerializer do
  let!(:location) { create :location }

  subject { location.serialize_as_json }

  it 'has fields we expect it to have' do
    hash = JSON.parse(subject)['location']
    expect(hash.delete('id'         )).to eq(location.id)
    expect(hash.delete('name'       )).to eq(location.name)
    expect(hash.delete('description')).to eq(location.description)
    expect(hash).to be_empty
  end
end
