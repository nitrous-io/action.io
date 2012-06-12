require 'spec_helper'

describe RegionSerializer do
  let!(:region) { create :region }

  subject { region.serialize_as_json }

  it 'has only id, name, and description fields' do
    hash = JSON.parse(subject)
    hash.delete('id'         ).should == region.id
    hash.delete('name'       ).should == region.name
    hash.delete('description').should == region.description
    hash.should be_empty
  end
end

