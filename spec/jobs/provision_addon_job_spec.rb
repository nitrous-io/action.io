require 'spec_helper'

describe ProvisionAddonJob do
  describe '#perform' do
    let!(:addon_subscription) { create :addon_subscription }

    before do
      AddonSubscription.stub!(:find).with(addon_subscription.id) { addon_subscription }
    end

    context "with no required vars" do
      before do
        @job = ProvisionAddonJob.new(addon_subscription.id)
      end

      it 'calls provision_addon method on addon_subscription' do
        addon_subscription.should_receive(:provision_addon).once.ordered.with({})
        @job.perform
      end
    end

    context "with required vars" do
      before do
        @job = ProvisionAddonJob.new(addon_subscription.id, {'AWS_RDS_URL' => 'mysql://fakeurl'})
      end

      it 'calls provision_addon method on addon_subscription' do
        addon_subscription.should_receive(:provision_addon).once.ordered.with({'AWS_RDS_URL' => 'mysql://fakeurl'})
        @job.perform
      end
    end
  end
end

