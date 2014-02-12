require 'spec_helper'

describe BoxSerializer do

  let!(:region) { create :region, box_server_uri: 'https://boxserver.example.com:1234', enabled: true }
  let!(:box)    { create :box,
                    region: region,
                    version: 'arya',
                    auth_username: 'admin',
                    auth_password: 'password',
                    custom_domain: 'whoami.local' }

  subject { box.serialize_as_json }

  it 'has fields we expect it to have' do
    hash = JSON.parse(subject)['box']
    expect(hash.delete('id'             )).to eq(box.id)
    expect(hash.delete('name'           )).to eq(box.name)
    expect(hash.delete('container_name' )).to eq(box.container_name)
    expect(hash.delete('version'        )).to eq(box.version)
    expect(hash.delete('host'           )).to eq(box.host)
    expect(hash.delete('state'          )).to eq(box.state)
    expect(hash.delete('memory'         )).to eq(box.memory)
    expect(hash.delete('storage'        )).to eq(box.storage)
    expect(hash.delete('cpu_multiplier' )).to eq(box.cpu_multiplier)
    expect(hash.delete('virtual_memory' )).to eq(box.virtual_memory)
    expect(hash.delete('n2o_cost'       )).to eq(box.n2o_cost)
    expect(hash.delete('expected_cpu_multiplier')).to eq(box.expected_cpu_multiplier)
    expect(hash.delete('expected_virtual_memory')).to eq(box.expected_virtual_memory)
    expect(hash.delete('box_template_id')).to eq(box.box_template_id)
    expect(hash.delete('owner_id'       )).to eq(box.owner_id)
    expect(hash.delete('region_id'      )).to eq(box.region_id)
    expect(hash.delete('port'           )).to eq(box.port)
    expect(hash.delete('source_snapshot_id')).to eq(box.source_snapshot_id)
    expect(hash.delete('box_server_uri' )).to eq('https://boxserver.example.com:1234')
    expect(hash.delete('backend_available')).to eq(box.backend_available?)
    expect(hash.delete('auth_username'  )).to eq(box.auth_username)
    expect(hash.delete('auth_password'  )).to eq(box.auth_password)
    expect(hash.delete('force_shutdown' )).to eq(box.force_shutdown?)
    expect(hash.delete('custom_domain'  )).to eq(box.custom_domain)
    expect(hash).to be_empty
  end
end

