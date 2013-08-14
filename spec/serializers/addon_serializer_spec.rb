require 'spec_helper'

describe AddonSerializer do
  let!(:addon)  { create :addon }

  subject { addon.serialize_as_json }

  it 'has only id and uid as part of the attributes' do
    hash = JSON.parse(subject)['addon']
    hash.delete('id').should == addon.id
    hash.delete('uid').should == addon.uid
    hash.delete('name').should == addon.name
    hash.delete('tagline').should == addon.tagline
    hash.delete('addon_category')["id"].should == addon.addon_category.id
    hash.should be_empty
  end
end


