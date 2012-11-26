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
    let!(:addon)              { create :addon, config_vars: "RDS_URL", required_vars: {}, uid: 'rds', production_base_url: "https://rds.action.io/aio/resources", password: "password", state: "provisioning" }
    let!(:addon_subscription) { create :addon_subscription, box: box, addon: addon, state: 'provisioning' }
    let!(:resource)           { { id: 'resource_id', config: { "RDS_URL" => "mysql://foo@bar:fake_url" } } }

    context 'successful provisioning' do
      before do
        AddonSubscription.any_instance.stub(:push_addon_updated_message)
      end

      context 'without required vars' do
        it 'should make a call to the Provisioning API of the addon and set env_vars and resource_id of the addon_subscription' do
          stub_request(:post, "https://rds:password@rds.action.io/aio/resources").
            with(query: {}).
            to_return(body: resource.to_json)
          addon_subscription.provision_addon!

          addon_subscription.reload.resource_id.should == 'resource_id'
          JSON.parse(addon_subscription.env_vars).should == { "RDS_URL" => "mysql://foo@bar:fake_url" }
          addon_subscription.state.should == 'configuring'
        end
      end

      context 'with required vars' do
        before do
          addon.update_attribute(:required_vars, ["RDS_URL"])
        end

        it 'should make a call to the Provisioning API with the required vars of the addon and set env_vars and resource_id of the addon_subscription' do
          stub_request(:post, "https://rds:password@rds.action.io/aio/resources").
            with(query: { options: { "RDS_URL" => "mysql://foo@bar:fake_url" } }).
            to_return(body: resource.to_json)
          addon_subscription.provision_addon!("RDS_URL" => "mysql://foo@bar:fake_url")

          addon_subscription.reload.resource_id.should == 'resource_id'
          JSON.parse(addon_subscription.env_vars).should == { "RDS_URL" => "mysql://foo@bar:fake_url" }
          addon_subscription.state.should == 'configuring'
        end
      end
    end
  end
end
