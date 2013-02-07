require 'spec_helper'

describe SnapshotSerializer do
  let!(:snapshot)    { create :snapshot }

  subject { snapshot.serialize_as_json }

  it 'has snapshot attributes' do
    hash = JSON.parse(subject)['snapshot']
    hash.delete('id'             ).should == snapshot.id
    hash.delete('name'           ).should == snapshot.name
    hash.delete('description'    ).should == snapshot.description
    hash.delete('url'            ).should == snapshot.url
    hash.delete('state'          ).should == snapshot.state
    hash.delete('box_id'         ).should == snapshot.box_id
    hash.delete('owner_id'       ).should == snapshot.owner_id
    hash.should be_empty
  end
end
