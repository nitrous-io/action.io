require 'spec_helper'

describe ConfigureAddonJob do
  describe '#perform' do
    let(:addon_subscription) { create :addon_subscription }
    let(:job) { ConfigureAddonJob.new(addon_subscription.id) }

    before do
      AddonSubscription.stub!(:find).with(addon_subscription.id) { addon_subscription }
    end

    it 'calls configure_addon method on addon_subscription' do
      addon_subscription.should_receive(:configure_addon!)
      job.perform
    end
  end
end
