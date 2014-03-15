require 'spec_helper'

describe OrgSerializer do
  let!(:org) { create :org }

  subject { org.serialize_as_json }

  it 'has only id, name, permalink fields' do
    hash = JSON.parse(subject)['org']
    expect(hash.delete('id'             )).to eq(org.id)
    expect(hash.delete('name'           )).to eq(org.name)
    expect(hash.delete('permalink'      )).to eq(org.permalink)
    expect(hash).to be_empty
  end
end

