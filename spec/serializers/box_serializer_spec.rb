require 'spec_helper'

describe BoxSerializer do

  let!(:region) { create :region, box_server_uri: 'https://boxserver.example.com:1234', enabled: true }
  let!(:box)    { create :box, region: region, version: 'arya', auth_username: 'admin', auth_password: 'password'  }

  subject { box.serialize_as_json }

  it 'has fields we expect it to have' do
    hash = JSON.parse(subject)['box']
    hash.delete('id'             ).should == box.id
    hash.delete('name'           ).should == box.name
    hash.delete('container_name' ).should == box.container_name
    hash.delete('version'        ).should == box.version
    hash.delete('host'           ).should == box.host
    hash.delete('state'          ).should == box.state
    hash.delete('memory'         ).should == box.memory
    hash.delete('storage'        ).should == box.storage
    hash.delete('cpu_multiplier' ).should == box.cpu_multiplier
    hash.delete('virtual_memory').should == box.virtual_memory
    hash.delete('expected_cpu_multiplier').should == box.expected_cpu_multiplier
    hash.delete('expected_virtual_memory').should == box.expected_virtual_memory
    hash.delete('box_template_id').should == box.box_template_id
    hash.delete('owner_id'       ).should == box.owner_id
    hash.delete('region_id'      ).should == box.region_id
    hash.delete('port'           ).should == box.port
    hash.delete('box_server_uri' ).should == 'https://boxserver.example.com:1234'
    hash.delete('backend_available').should == box.backend_available?
    hash.delete('auth_username'  ).should == box.auth_username
    hash.delete('auth_password'  ).should == box.auth_password
    hash.should be_empty
  end
end

