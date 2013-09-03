require 'spec_helper'

describe BoxSerializer do

  let!(:region) { create :region, box_server_uri: 'https://boxserver.example.com:1234', enabled: true }
  let!(:box)    { create :box, region: region, version: 'arya' }

  subject { box.serialize_as_json }

  it 'has only id, name, host, state, box_template_id, owner_id, region_id, version and port fields' do
    hash = JSON.parse(subject)['box']
    hash.delete('id'             ).should == box.id
    hash.delete('name'           ).should == box.name
    hash.delete('container_name' ).should == box.container_name
    hash.delete('version'        ).should == box.version
    hash.delete('host'           ).should == box.host
    hash.delete('state'          ).should == box.state
    hash.delete('memory'         ).should == box.memory
    hash.delete('storage'        ).should == box.storage
    hash.delete('box_template_id').should == box.box_template_id
    hash.delete('owner_id'       ).should == box.owner_id
    hash.delete('region_id'      ).should == box.region_id
    hash.delete('port'           ).should == box.port
    hash.delete('box_server_uri' ).should == 'https://boxserver.example.com:1234'
    hash.delete('backend_available' ).should == box.backend_available?
    hash.should be_empty
  end
end

