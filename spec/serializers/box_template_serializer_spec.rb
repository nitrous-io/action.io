require 'spec_helper'

describe BoxTemplateSerializer do
  let!(:box_template) { create :box_template }

  subject { box_template.serialize_as_json }

  it 'has only id, name, and description fields' do
    hash = JSON.parse(subject)['box_template']
    expect(hash.delete('id'         )).to eq(box_template.id)
    expect(hash.delete('name'       )).to eq(box_template.name)
    expect(hash.delete('description')).to eq(box_template.description)
    expect(hash.delete('enabled'    )).to eq(box_template.enabled)
    expect(hash.delete('runtime'    )).to eq(box_template.runtime)
    expect(hash).to be_empty
  end
end
