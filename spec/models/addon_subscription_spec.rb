require 'spec_helper'

describe AddonSubscription do
  let(:box)                 { create :box }
  let(:production_base_url) { 'https://rds.action.io/aio/resources' }

  it_behaves_like 'a model that has an encrypted attribute', AddonSubscription, :env_vars

  it { should belong_to :box }
  it { should belong_to :addon_plan }

  it { should_not allow_mass_assignment_of :box_id }
  it { should_not allow_mass_assignment_of :addon_plan_id }

  describe '#push_addon_updated_message' do
    let(:user1)              { create :user }
    let(:user2)              { create :user }
    let(:user3)              { create :user }
    let(:box)                { create :box, owner: user1, users: [user1, user3] }
    let(:addon_plan)         { create :addon_plan }
    let(:addon)              { addon_plan.addon }
    let(:addon_subscription) { create :addon_subscription, box: box, addon_plan: addon_plan }

    it 'pushes aio:addon_updated notification' do
      channel = double('channel')
      [user1, user3].each do |user|
        Pusher.should_receive(:[]).with("private-user-#{user.id}") { channel }
        channel.should_receive(:trigger).ordered.with('aio:addon_updated', addon.serialize_as_hash)
      end
      addon_subscription.push_addon_updated_message
    end
  end

  describe '#provision' do
    let(:addons_url) { 'https://rds:password@rds.action.io/aio/resources' }
    let(:rds_url) { 'mysql://foo@bar:fake_url' }
    let(:resource) { { id: 'resource_id', config: { 'RDS_URL' => rds_url } } }
    let(:addon) do
      create :addon, config_vars: 'RDS_URL', required_vars: {},
        uid: 'rds', production_base_url: production_base_url,
        password: 'password'
    end
    let(:addon_plan) { create :addon_plan, addon: addon }
    let(:addon_subscription) { create :addon_subscription, box: box, addon_plan: addon_plan, state: "provisioning" }
    let(:coach) { mock :coach }

    before do
      AddonSubscription.any_instance.stub(:push_addon_updated_message)
      addon_subscription.box.stub(:coach) { coach }
    end

    context 'successful provisioning' do
      before do
        stub_request(:post, addons_url).
          with(body: {nitrous_id: box.id}.to_json).
          to_return(body: resource.to_json)
      end

      it 'should call the Provisioning API and set env_vars, resource_id' do
        coach.should_receive(:set_environment_variables).with(resource[:config]) { true }
        addon_subscription.provision
        addon_subscription.reload.resource_id.should == 'resource_id'
        JSON.parse(addon_subscription.env_vars).should == resource[:config]
        addon_subscription.state.should == 'provisioned'
      end

      context 'when unable to configure the box' do
        before { coach.stub(:set_environment_variables) { false } }

        it 'should raise an exception' do
          expect {
            addon_subscription.provision
          }.to raise_error AddonSubscription::AddonSubscriptionError
        end
      end
    end # successful provisioning

    context 'unsuccessful provisioning' do
      before { coach.should_not_receive(:set_environment_variables) }

      it 'should raise an exception when fail to authenticate' do
        stub_request(:post, addons_url).to_return(body: 'Authentication failure', status: 403)
        expect { addon_subscription.provision }.to raise_error
      end

      it 'should raise an exception when receive bad request' do
        stub_request(:post, addons_url).to_return(body: '', status: 400)
        expect { addon_subscription.provision }.to raise_error
      end

      it 'should raise an exception when timeout' do
        stub_request(:post, addons_url).to_timeout
        expect { addon_subscription.provision }.to raise_error
      end
    end
  end

  describe '#deprovision' do
    let(:addon) do
      create :addon, config_vars: ['RDS_URL'], required_vars: {},
        uid: 'rds', production_base_url: production_base_url,
        password: 'password'
    end
    let(:addon_plan) { create :addon_plan, addon: addon }
    let(:addon_subscription) { create :addon_subscription, box: box, addon_plan: addon_plan, state: "deprovisioning" }
    let(:delete_url) { "https://rds:password@rds.action.io/aio/resources/#{box.id}" }
    let(:coach) { mock :coach }

    before do
      AddonSubscription.any_instance.stub(:push_addon_updated_message)
      addon_subscription.box.stub(:coach) { coach }
    end

    context 'successful deprovision' do
      before do
        stub_request(:delete, delete_url).to_return(body: "deleted")
      end

      it 'should call the Provisioning API to remove env vars and resource_id' do
        coach.should_receive(:remove_environment_variables).with(['RDS_URL']) { true }
        addon_subscription.deprovision
        addon_subscription.reload
        addon_subscription.state.should eq('deprovisioned')
        addon_subscription.resource_id.should_not be_present
      end
    end

    context 'unsuccessful deprovision' do
      before do
        stub_request(:delete, delete_url).to_return(body: "", status: 500)
        coach.stub(:remove_environment_variables)
      end

      it 'doesnt change the subscription and remove end variables' do
        coach.should_receive(:remove_environment_variables).with(['RDS_URL']) { true }
        expect { addon_subscription.deprovision }.to raise_error
        addon_subscription.reload
        addon_subscription.state.should eq('deprovisioning')
      end
    end
  end

  describe '.provision' do
    let(:addon_plan) { create :addon_plan }
    let(:box_id) { box.id }
    before do
      AddonSubscription.any_instance.stub(:push_addon_updated_message)
    end

    context "when user hasnt subscribe to this addon" do
      it 'creates a new provisioning subscription' do
        subscription = AddonSubscription.provision addon_plan, box
        subscription.should be_persisted
        subscription.state.should eq("provisioning")
      end
    end

    context 'when there is an existing resource' do
      before { AddonSubscription.destroy_all }

      it 'provisions a new subscription' do
        create :addon_subscription, addon_plan: addon_plan, box: box, state: "provisioning"
        expect {
          AddonSubscription.provision addon_plan, box
        }.to change { AddonSubscription.count }.by 1
      end

      context "when the box reached quota for plans belongs to same addon" do
        let(:addon) { create :addon }
        let(:addon_plan1) { create :addon_plan, addon: addon }
        let(:addon_plan2) { create :addon_plan, addon: addon}

        before do
          (AddonSubscription::LIMIT-1).times { create :addon_subscription, box: box, addon_plan: addon_plan1 }
          create :addon_subscription, box: box, addon_plan: addon_plan2
        end

        it 'does not allow user to subscribe for that addon' do
          subscription = AddonSubscription.provision addon_plan1, box
          subscription.should_not be_persisted
          subscription.should_not be_valid
        end

        it 'doesnt count deprovisioned addons' do
          AddonSubscription.last.update_attribute :state, :deprovisioned
          expect {
            AddonSubscription.provision addon_plan1, box
          }.not_to raise_error
        end
      end
    end
  end

  describe '.deprovision' do
    context "when the subscription is provisioned" do
      let!(:subscription) { create :addon_subscription, state: "provisioned" }
      before do
        AddonSubscription.any_instance.stub(:push_addon_updated_message)
      end

      it 'moves the subscription to deprovisioning state first' do
        AddonSubscription.deprovision subscription
        subscription.state.should eq("deprovisioning")
      end
    end
  end
end
