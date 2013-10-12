require 'spec_helper'

describe RegionSerializer do
  let!(:region) { create :region }

  subject { region.serialize_as_json }

  it 'has only id, name, label and description fields' do
    hash = JSON.parse(subject)['region']
    hash.delete('id'         ).should == region.id
    hash.delete('name'       ).should == region.name
    hash.delete('description').should == region.description
    hash.delete('state'      ).should == region.state
    hash.delete('label'      ).should == region.label
    hash.should be_empty
  end
end

