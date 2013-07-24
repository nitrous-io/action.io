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
    let(:addons_url) { 'https://rds:password@rds.action.io/aio/resources' }
    let(:rds_url) { 'mysql://foo@bar:fake_url' }
    let(:resource) { { id: 'resource_id', config: { 'RDS_URL' => rds_url } } }
    let(:addon) do
      create :addon, config_vars: 'RDS_URL', required_vars: {},
        uid: 'rds', production_base_url: production_base_url,
        password: 'password', state: 'provisioning'
    end
    let(:addon_subscription) do
      create :addon_subscription, box: box, addon: addon, state: 'provisioning'
    end

    context 'successful provisioning' do
      before { AddonSubscription.any_instance.stub(:push_addon_updated_message) }

      it 'should call the Provisioning API and set env_vars, resource_id' do
        stub_request(:post, addons_url).
          with(query: {}).
          to_return(body: resource.to_json)
        addon_subscription.provision_addon!

        addon_subscription.reload.resource_id.should == 'resource_id'
        JSON.parse(addon_subscription.env_vars).should == resource[:config]
        addon_subscription.state.should == 'configuring'
      end
    end # successful provisioning

    context 'unsuccessful provisioning' do
      subject { addon_subscription.provision_addon! }
      before { addon_subscription.should_not_receive(:enqueue_configure!) }

      it 'should raise an exception when fail to authenticate' do
        stub_request(:post, addons_url).to_return(body: 'Authentication failure', status: 403)
        expect { subject }.to raise_error StandardError
      end

      it 'should raise an exception when receive bad request' do
        stub_request(:post, addons_url).to_return(body: '', status: 400)
        expect { subject }.to raise_error StandardError
      end

      it 'should raise an exception when timeout' do
        stub_request(:post, addons_url).to_timeout
        expect { subject }.to raise_error StandardError
      end
    end
  end

  describe 'configure' do
    let(:addon) { create :addon, state: 'configured' }
    let(:addon_subscription) do
      create :addon_subscription, box: box, addon: addon,
      state: 'configured', env_vars: 'foo vars'
    end

    context 'successful configuration' do
      before do
        addon_subscription.should_receive(:push_addon_updated_message)
        addon_subscription.box.coach.stub(:set_environment_variables) { true }
      end

      it 'should request Coach to set env variables and transit to subscribing' do
        addon_subscription.configure
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
            addon_subscription.configure
          }.to raise_error AddonSubscription::AddonSubscriptionError
        end
      end
    end
  end
end
