require 'spec_helper'

describe PushBillingProfileUpdatedJob do
  let!(:user) { create :user }
  let!(:billing_profile) { create :billing_profile, user: user }

  describe '#perform' do
    let(:channel) { double.as_null_object }

    before do
      Pusher.stub(:[]).with("private-user-#{user.id}") { channel }
      channel.stub(:trigger)
    end

    it "sends the given billing profile a serialized JSON object to the web app via Shover" do
      expect(Shover).to receive(:publish).with(user.id, 'aio:billing_profile_updated', billing_profile.serialize_as_hash)
      channel.should_receive(:trigger) do |message, data|
        message.should eq 'aio:billing_profile_updated'
        data.should eq(billing_profile.serialize_as_hash)
      end

      PushBillingProfileUpdatedJob.new(billing_profile.id).perform
    end
  end

  describe '.submit_job' do
    it 'should submit a delayed job' do
      expect {
        PushBillingProfileUpdatedJob.submit_job(billing_profile.id)
      }.to change(Delayed::Job, :count).by(1)

      Delayed::Job.last.handler.should match(/PushBillingProfileUpdatedJob.*?billing_profile_id: #{billing_profile.id}/m)
    end
  end
end
