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

    it "sends the given billing profile as a serialized JSON object to the web app via Shover" do
      expect(Shover).to receive(:publish).with(user.id, 'aio:billing_profile_updated', billing_profile.serialize_as_hash)
      expect(channel).to receive(:trigger) do |message, data|
        expect(message).to eq 'aio:billing_profile_updated'
        expect(data).to eq(billing_profile.serialize_as_hash)
      end

      PushBillingProfileUpdatedJob.new(user.id).perform
    end
  end

  describe '.submit_job' do
    it 'should submit a delayed job' do
      expect {
        PushBillingProfileUpdatedJob.submit_job(user.id)
      }.to change(Delayed::Job, :count).by(1)

      expect(Delayed::Job.last.handler).to match(/PushBillingProfileUpdatedJob.*?user_id: #{user.id}/m)
    end
  end
end
