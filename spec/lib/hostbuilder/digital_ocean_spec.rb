require 'spec_helper'

xdescribe Hostbuilder::DigitalOcean do
  let!(:boxhost_provider_template) { create :boxhost_provider_template, config: { image_id: 123, host_region_id: 456, size_id: 789 } }
  let!(:user) { create :user }
  let!(:boxhost) { create :dedicated_boxhost, owner: user, boxhost_provider_template: boxhost_provider_template }
  let!(:hostbuilder) { Hostbuilder::DigitalOcean.new(boxhost) }
  let!(:apt_repo_app) { Doorkeeper::Application.create name: 'apt.nitrous.io', redirect_uri: 'http://example.com' }
  let!(:token) { Doorkeeper::AccessToken.create(resource_owner_id: user.id, application_id: apt_repo_app.id, scopes: 'user') }

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
              public_keys: boxhost.public_keys,
              apt_username: user.username,
              apt_password: token.token,
              apt_dist: 'trusty',
              apt_location: 'apt.nitrous.io',
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
              public_keys: boxhost.public_keys,
              apt_username: user.username,
              apt_password: token.token,
              apt_dist: 'trusty',
              apt_location: 'apt.nitrous.io',
            })
          }).to_return(body: '{"status":"invalid config"}')

        expect {
          hostbuilder.create('https://webhook/created')
        }.to raise_error Hostbuilder::HostbuilderError
      end
    end
  end
end
