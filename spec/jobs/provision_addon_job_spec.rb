require 'spec_helper'

describe ProvisionAddonJob do
  describe '#perform' do
    let(:addon_subscription) { create :addon_subscription }

    it 'calls provision_addon method on addon_subscription' do
      job = ProvisionAddonJob.new(addon_subscription.id)
      AddonSubscription.stub!(:find).with(addon_subscription.id) { addon_subscription }
      addon_subscription.should_receive(:provision).once
      job.perform
    end
  end
end

