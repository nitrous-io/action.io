require 'spec_helper'

describe AddonSubscription do
  let(:box)                 { create :box }
  let(:production_base_url) { 'https://rds.action.io/aio/resources' }

  it_behaves_like 'a model that has an encrypted attribute', AddonSubscription, :env_vars

  it { should belong_to :box }
  it { should belong_to :addon }

  it { should_not allow_mass_assignment_of :box_id }
  it { should_not allow_mass_assignment_of :addon_id }

  describe '#push_addon_updated_message' do
    let(:user1)              { create :user }
    let(:user2)              { create :user }
    let(:user3)              { create :user }
    let(:box)                { create :box, owner: user1, users: [user1, user3] }
    let(:addon)              { create :addon }
    let(:addon_subscription) { create :addon_subscription, box: box, addon: addon }

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
    let(:addons_url)    { 'https://rds:password@rds.action.io/aio/resources' }
    let(:rds_url)       { 'mysql://foo@bar:fake_url' }
    let(:resource)      { { id: 'resource_id', config: { 'RDS_URL' => rds_url } } }
    let(:required_vars) { { 'RDS_URL' => rds_url } }
    let(:addon) do
      create :addon, config_vars: 'RDS_URL', required_vars: {},
      uid: 'rds', production_base_url: production_base_url,
      password: 'password'
    end
    let(:addon_subscription) do
      create :addon_subscription, box: box, addon: addon, state: 'provisioning'
    end

    context 'successful provisioning' do
      before { AddonSubscription.any_instance.stub(:push_addon_updated_message) }

      context 'without required vars' do
        it 'should call the Provisioning API and set env_vars, resource_id' do
          stub_request(:post, addons_url).
            with(body: {}).
            to_return(body: resource.to_json)
          addon_subscription.provision_addon!

          addon_subscription.reload.resource_id.should == 'resource_id'
          JSON.parse(addon_subscription.env_vars).should == required_vars
          addon_subscription.state.should == 'configuring'
        end
      end

      context 'with required vars' do
        before { addon.update_attribute(:required_vars, ['RDS_URL']) }

        it 'should call the Provisioning API with required vars and set env_vars, resource_id' do
          stub_request(:post, addons_url).
            with(body: { options: required_vars }).
            to_return(body: resource.to_json)
          addon_subscription.provision_addon!(required_vars)

          addon_subscription.reload.resource_id.should == 'resource_id'
          JSON.parse(addon_subscription.env_vars).should == required_vars
          addon_subscription.state.should == 'configuring'
        end
      end
    end # successful provisioning

    context 'unsuccessful provisioning' do
      subject { addon_subscription.provision_addon! }
      before { addon_subscription.should_not_receive(:enqueue_configure!) }

      context 'authentication failure' do
        it 'should raise an exception' do
          stub_request(:post, addons_url).to_return(body: 'Authentication failure', status: 403)
          expect { subject }.to raise_error AddonSubscription::AddonSubscriptionError
        end
      end

      context 'bad request' do
        it 'should raise an exception' do
          stub_request(:post, addons_url).to_return(body: '', status: 400)
          expect { subject }.to raise_error AddonSubscription::AddonSubscriptionError
        end
      end

      context 'request timeout' do
        it 'should raise an exception' do
          stub_request(:post, addons_url).to_timeout
          expect { subject }.to raise_error Timeout::Error
        end
      end
    end
  end

  describe 'deprovision_addon!' do
    let(:addons_url)    { 'https://rds:password@rds.action.io/aio/resources' }
    let(:rds_url)       { 'mysql://foo@bar:fake_url' }
    let(:resource)      { { id: 'resource_id', config: { 'RDS_URL' => rds_url } } }
    let(:resource_id)   { 'nasi-lemak' }
    let(:required_vars) { { 'RDS_URL' => rds_url } }
    let(:addon) do
      create :addon, config_vars: 'RDS_URL', required_vars: {},
      uid: 'rds', production_base_url: production_base_url,
      password: 'password'
    end
    let(:addon_subscription) do
      create :addon_subscription, box: box, addon: addon,
      state: 'deprovisioning', resource_id: resource_id
    end

    context 'successful deprovisioning' do
      before { AddonSubscription.any_instance.stub(:push_addon_updated_message) }

      it 'should call the Provisioning API and unset resource_id' do
        stub_request(:delete, "#{addons_url}/#{resource_id}").
          with(body: {}).
          to_return(body: resource.to_json)
        addon_subscription.deprovision_addon!

        addon_subscription.reload.resource_id.should be_nil
        addon_subscription.state.should == 'deconfiguring'
      end
    end

    context 'unsuccessful deprovisioning' do
      subject { addon_subscription.deprovision_addon! }
      before { addon_subscription.should_not_receive(:enqueue_deconfigure!) }

      context 'authentication failure' do
        it 'should raise an exception' do
          stub_request(:delete, "#{addons_url}/#{resource_id}").to_return(body: 'Authentication failure', status: 403)
          expect { subject }.to raise_error AddonSubscription::AddonSubscriptionError
        end
      end

      context 'bad request' do
        it 'should raise an exception' do
          stub_request(:delete, "#{addons_url}/#{resource_id}").to_return(body: '', status: 400)
          expect { subject }.to raise_error AddonSubscription::AddonSubscriptionError
        end
      end

      context 'request timeout' do
        it 'should raise an exception' do
          stub_request(:delete, "#{addons_url}/#{resource_id}").to_timeout
          expect { subject }.to raise_error Timeout::Error
        end
      end
    end
  end

  describe 'configure_addon!' do
    let(:addon) { create :addon }
    let(:addon_subscription) do
      create :addon_subscription, box: box, addon: addon,
      state: 'configuring', env_vars: 'foo vars'
    end

    context 'successful configuration' do
      before do
        addon_subscription.should_receive(:push_addon_updated_message).twice
        addon_subscription.box.coach.stub(:set_environment_variables) { true }
        addon_subscription.box.should_receive(:enqueue_restart!) { true }
      end

      it 'should request Coach to set env variables and transit to configured' do
        addon_subscription.configure_addon!
        addon_subscription.state.should == 'subscribing'
      end
    end

    context 'unsuccessful configuration' do
      before do
        addon_subscription.should_not_receive(:push_addon_updated_message)
        addon_subscription.box.coach.stub(:set_environment_variables) { false }
      end

      context 'unsuccessful request' do
        it 'should raise an exception' do
          expect {
            addon_subscription.configure_addon!
          }.to raise_error AddonSubscription::AddonSubscriptionError
        end
      end
    end
  end

  describe 'deconfigure_addon!' do
    let(:addon) { create :addon }
    let(:addon_subscription) do
      create :addon_subscription, box: box, addon: addon,
      state: 'deconfiguring', env_vars: 'foo vars'
    end

    context 'successful deconfiguration' do
      before do
        addon_subscription.should_receive(:push_addon_updated_message).twice
        addon_subscription.box.coach.stub(:remove_environment_variables) { true }
        addon_subscription.box.should_receive(:enqueue_restart!) { true }
      end

      it 'should request Coach to remove env variables and transit to deconfigured' do
        addon_subscription.deconfigure_addon!
        addon_subscription.state.should == 'unsubscribing'
      end
    end

    context 'unsuccessful deconfiguration' do
      before do
        addon_subscription.should_not_receive(:push_addon_updated_message)
        addon_subscription.box.coach.stub(:remove_environment_variables) { false }
      end

      context 'unsuccessful request' do
        it 'should raise an exception' do
          expect {
            addon_subscription.deconfigure_addon!
          }.to raise_error AddonSubscription::AddonSubscriptionError
        end
      end
    end
  end
end
