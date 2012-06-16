require 'spec_helper'

describe BoxSerializer do
  before :all do
    ENV['ACTION_BOX_SERVER_URI'] = 'https://boxserver.example.com:1234'
  end

  let!(:box) { create :box }

  subject { box.serialize_as_json }

  it 'has only id, name, host, state, box_template_id, owner_id, region_id, and port fields' do
    hash = JSON.parse(subject)
    hash.delete('id'             ).should == box.id
    hash.delete('name'           ).should == box.name
    hash.delete('host'           ).should == box.host
    hash.delete('state'          ).should == box.state
    hash.delete('box_template_id').should == box.box_template_id
    hash.delete('owner_id'       ).should == box.owner_id
    hash.delete('region_id'      ).should == box.region_id
    hash.delete('port'           ).should == box.port
    hash.delete('box_server_uri' ).should == ENV['ACTION_BOX_SERVER_URI']
    hash.should be_empty
  end
end

