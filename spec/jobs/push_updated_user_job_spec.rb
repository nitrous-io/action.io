require 'spec_helper'

describe PushUpdatedUserJob do
  describe '#perform' do
    let(:channel) { double.as_null_object }

    it "sends a message via Pusher with the user to the user's channel" do
      user = double.as_null_object
      User.stub(:find).with(69) { user }
      user.should_receive(:serialize_as_hash) { { user: { id: 69, username: 'emmawatson' } } }

      expect(Pusher).to receive(:[]).with('private-user-69') { channel }
      expect(channel).to receive(:trigger) do |message, data|
        message.should == 'aio:user_updated'
        data.should == { user: { id: 69, username: 'emmawatson' } }.to_json
      end

      PushUpdatedUserJob.new(69).perform
    end
  end

  describe '.submit_job' do
    it 'should submit a delayed job to push the updated user record' do
      expect {
        PushUpdatedUserJob.submit_job(123)
      }.to change(Delayed::Job, :count).by(1)

      Delayed::Job.last.handler.should match(/PushUpdatedUserJob/)
      Delayed::Job.last.handler.should match(/user_id: 123/)
    end
  end
end
