require 'spec_helper'

describe AddonSubscription do
  it_behaves_like 'a model that has an encrypted attribute', AddonSubscription, :env_vars

  it { should belong_to :box }
  it { should belong_to :addon }

  it { should_not allow_mass_assignment_of :box_id }
  it { should_not allow_mass_assignment_of :addon_id }

  describe '#push_addon_updated_message' do
    let(:user1)               { create :user }
    let(:user2)               { create :user }
    let(:user3)               { create :user }
    let!(:box)                { create :box, owner: user1, users: [user1, user3] }
    let!(:addon)              { create :addon }
    let!(:addon_subscription) { create :addon_subscription, box: box, addon: addon }

    it 'pushes aio:addon_updated notification' do
      channel = double('channel')
      [user1, user3].each do |user|
        Pusher.should_receive(:[]).with("private-user-#{user.id}") { channel }
        channel.should_receive(:trigger).ordered.with('aio:addon_updated', addon.serialize_as_hash)
      end

      addon_subscription.push_addon_updated_message
    end
  end

  describe 'provision_addon!' do
    let!(:box)                { create :box }
    let!(:addons_url)         { 'https://rds:password@rds.action.io/aio/resources' }
    let!(:rds_url)            { 'mysql://foo@bar:fake_url' }
    let!(:addon)              { create :addon, config_vars: 'RDS_URL', required_vars: {}, uid: 'rds', production_base_url: 'https://rds.action.io/aio/resources', password: 'password', state: 'provisioning' }
    let!(:addon_subscription) { create :addon_subscription, box: box, addon: addon, state: 'provisioning' }
    let!(:resource)           { { id: 'resource_id', config: { 'RDS_URL' => rds_url } } }

    context 'successful provisioning' do
      before do
        AddonSubscription.any_instance.stub(:push_addon_updated_message)
      end

      context 'without required vars' do
        it 'should make a call to the Provisioning API of the addon and set env_vars and resource_id of the addon_subscription' do
          stub_request(:post, addons_url).
            with(query: {}).
            to_return(body: resource.to_json)
          addon_subscription.provision_addon!

          addon_subscription.reload.resource_id.should == 'resource_id'
          JSON.parse(addon_subscription.env_vars).should == { 'RDS_URL' => rds_url }
          addon_subscription.state.should == 'configuring'
        end
      end

      context 'with required vars' do
        before do
          addon.update_attribute(:required_vars, ['RDS_URL'])
        end

        it 'should make a call to the Provisioning API with the required vars of the addon and set env_vars and resource_id of the addon_subscription' do
          stub_request(:post, addons_url).
            with(query: { options: { 'RDS_URL' => rds_url } }).
            to_return(body: resource.to_json)
          addon_subscription.provision_addon!('RDS_URL' => rds_url)

          addon_subscription.reload.resource_id.should == 'resource_id'
          JSON.parse(addon_subscription.env_vars).should == { 'RDS_URL' => rds_url }
          addon_subscription.state.should == 'configuring'
        end
      end
    end # successful provisioning

    context 'unsuccessful provisioning' do
      before do
        addon_subscription.should_not_receive(:enqueue_configure!)
      end

      context 'authentication failure' do
        it 'should raise an exception' do
          stub_request(:post, addons_url).to_return(body: 'Authentication failure', status: 403)
          expect { addon_subscription.provision_addon! }.to raise_error StandardError
        end
      end

      context 'bad request' do
        it 'should raise an exception' do
          stub_request(:post, addons_url).to_return(body: '', status: 400)
          expect { addon_subscription.provision_addon! }.to raise_error StandardError
        end
      end

      context 'request timeout' do
        it 'should raise an exception' do
          stub_request(:post, addons_url).to_timeout
          expect { addon_subscription.provision_addon! }.to raise_error StandardError
        end
      end
    end # unsuccessful provisioning
  end # provision_addon!

  describe 'configure' do
    let!(:box)                { create :box }
    let!(:coach_url)          { box.region.coach_uri }
    let!(:configure_box_url)  { "#{coach_url}/boxes/#{box.name}/configure_box" }
    let!(:addon)              { create :addon, config_vars: 'RDS_URL', required_vars: {}, uid: 'rds', production_base_url: 'https://rds.action.io/aio/resources', password: 'password', state: 'configured' }
    let!(:addon_subscription) { create :addon_subscription, box: box, addon: addon, state: 'configured', env_vars: 'foo vars' }

    context 'successful configuration' do
      before do
        addon_subscription.should_receive(:push_addon_updated_message)
      end

      it 'should make a request to Coach with the env variables and restart' do
        payload = {
          box: {
            addon_id: addon_subscription.addon_id,
            env_vars: addon_subscription.env_vars
          }
        }
        stub_request(:put, configure_box_url).with(query: payload)
        addon_subscription.configure
        addon_subscription.state.should == 'restarting'
      end
    end

    context 'unsuccessful configuration' do
      context 'unsuccessful request' do
        it 'should raise an exception' do
          stub_request(:put, configure_box_url).to_return(body: '', status: 400)
          expect { addon_subscription.configure }.to raise_error StandardError
        end
      end

      context 'request timeout' do
        it 'should raise an exception' do
          stub_request(:put, configure_box_url).to_timeout
          expect { addon_subscription.configure }.to raise_error StandardError
        end
      end
    end # unsuccessful configuration
  end # configure

  describe 'restart' do
    let!(:box)                { create :box }
    let!(:coach_url)          { box.region.coach_uri }
    let!(:restart_url)        { "#{coach_url}/boxes/#{box.name}/restart" }
    let!(:addon)              { create :addon, config_vars: 'RDS_URL', required_vars: {}, uid: 'rds', production_base_url: 'https://rds.action.io/aio/resources', password: 'password', state: 'restarted' }
    let!(:addon_subscription) { create :addon_subscription, box: box, addon: addon, state: 'restarted', env_vars: 'foo vars' }

    context 'successful restart' do
      before do
        addon_subscription.should_receive(:push_addon_updated_message)
      end

      it 'should make a request to Coach to restart' do
        payload = {
          box: {
            addon_id: addon_subscription.addon_id,
            boxer_id: box.host
          }
        }
        stub_request(:put, restart_url).with(query: payload)
        addon_subscription.restart
        addon_subscription.state.should == 'subscribing'
      end
    end

    context 'unsuccessful restart' do
      context 'unsuccessful request' do
        it 'should raise an exception' do
          stub_request(:put, restart_url).to_return(body: '', status: 400)
          expect { addon_subscription.restart }.to raise_error StandardError
        end
      end

      context 'request timeout' do
        it 'should raise an exception' do
          stub_request(:put, restart_url).to_timeout
          expect { addon_subscription.restart }.to raise_error StandardError
        end
      end
    end
  end # restart
end # AddonSubscription
