require 'spec_helper'

describe DeprovisionAddonJob do
  describe '#perform' do
    let(:addon_subscription) { create :addon_subscription }
    let(:job) { DeprovisionAddonJob.new(addon_subscription.id) }

    before do
      AddonSubscription.stub!(:find).with(addon_subscription.id) { addon_subscription }
    end

    it 'calls deprovision_addon! method on addon_subscription' do
      addon_subscription.should_receive(:deprovision_addon!)
      job.perform
    end
  end
end
