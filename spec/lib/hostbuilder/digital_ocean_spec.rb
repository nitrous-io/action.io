require 'spec_helper'

describe Hostbuilder::DigitalOcean do
  let!(:boxhost_provider_template) { create :boxhost_provider_template, config: { image_id: 123, region_id: 456, size_id: 789 } }
  let!(:boxhost) { create :boxhost, boxhost_provider_template: boxhost_provider_template }
  let!(:hostbuilder) { Hostbuilder::DigitalOcean.new(boxhost) }

  describe '#create' do
    context 'successful provisioning' do
      it 'should make a HTTP request to the Hostbuilder API to create a new boxhost' do
        stub_request(:post, "#{ENV['HOSTBUILDER_URI']}/host").
          with(query: {
            provider: 'digitalocean',
            webhook: 'https://webhook/created',
            config: JSON.dump({
              name: boxhost.name,
              image_id: '123',
              region_id: '456',
              size_id: '789',
              public_keys: boxhost.public_keys
            })
          }).to_return(body: '{"status":"ok"}')

        expect(hostbuilder.create('https://webhook/created')).to be_truthy
      end
    end

    context 'unsuccessful provisioning' do
      it 'should make a HTTP request to the Hostbuilder API to create a new boxhost' do
        stub_request(:post, "#{ENV['HOSTBUILDER_URI']}/host").
          with(query: {
            provider: 'digitalocean',
            webhook: 'https://webhook/created',
            config: JSON.dump({
              name: boxhost.name,
              image_id: '123',
              region_id: '456',
              size_id: '789',
              public_keys: boxhost.public_keys
            })
          }).to_return(body: '{"status":"invalid config"}')

        expect {
          hostbuilder.create('https://webhook/created')
        }.to raise_error Hostbuilder::HostbuilderError
      end
    end
  end
end
