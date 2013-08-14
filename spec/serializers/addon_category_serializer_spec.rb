require 'spec_helper'

describe AddonCategorySerializer do
  let!(:addon_category)  { create :addon_category }

  subject { addon_category.serialize_as_json }

  it 'has only id and uid as part of the attributes' do
    hash = JSON.parse(subject)['addon_category']
    hash.delete('id').should == addon_category.id
    hash.delete('name').should == addon_category.name
    hash.delete('description').should == addon_category.description
    hash.delete('icon').should == addon_category.icon
    hash.should be_empty
  end
end


