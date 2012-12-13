require 'spec_helper'

describe UpdateAddonJob do
  describe '#perform' do
    let(:addon_subscription) { create :addon_subscription }

    before do
      AddonSubscription.stub!(:find).with(addon_subscription.id) { addon_subscription }
    end

    context "with no env vars" do
      let(:job) { UpdateAddonJob.new(addon_subscription.id) }

      it 'calls update_addon! method on addon_subscription' do
        addon_subscription.should_receive(:update_addon!).once.ordered.with({})
        job.perform
      end
    end

    context "with env vars" do
      let(:env_vars) { { env: 'environment' } }
      let(:job) { UpdateAddonJob.new(addon_subscription.id, env_vars) }

      it 'calls update_addon! method on addon_subscription' do
        addon_subscription.should_receive(:update_addon!).once.ordered.with(env_vars)
        job.perform
      end
    end
  end
end
