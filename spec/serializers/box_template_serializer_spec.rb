require 'spec_helper'

describe BoxTemplateSerializer do
  let!(:box_template) { create :box_template }

  subject { box_template.serialize_as_json }

  it 'has only id, name, and description fields' do
    hash = JSON.parse(subject)['box_template']
    hash.delete('id'         ).should == box_template.id
    hash.delete('name'       ).should == box_template.name
    hash.delete('description').should == box_template.description
    hash.should be_empty
  end
end
