require 'spec_helper'

describe PushSubscriptionUpdatedJob do
  let!(:user) { create :user }
  let!(:subscription) { create :subscription, user: user }

  describe '#perform' do
    let(:channel) { double.as_null_object }

    before do
      Pusher.stub(:[]).with("private-user-#{user.id}") { channel }
      channel.stub(:trigger)
    end

    it "sends the given subscription a serialized JSON object to the web app via Shover" do
      expect(Shover).to receive(:publish).with(user.id, 'aio:subscription_updated', subscription.serialize_as_hash)
      channel.should_receive(:trigger) do |message, data|
        message.should eq 'aio:subscription_updated'
        data.should eq(subscription.serialize_as_hash)
      end

      PushSubscriptionUpdatedJob.new(subscription.id).perform
    end
  end

  describe '.submit_job' do
    it 'should submit a delayed job' do
      expect {
        PushSubscriptionUpdatedJob.submit_job(subscription.id)
      }.to change(Delayed::Job, :count).by(1)

      Delayed::Job.last.handler.should match(/PushSubscriptionUpdatedJob.*?subscription_id: #{subscription.id}/m)
    end
  end
end
