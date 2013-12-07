require 'spec_helper'

describe PushCurrentN2oBalanceJob do
  describe '#perform' do
    let!(:user)   { create :user }
    let!(:job)    { PushCurrentN2oBalanceJob.new(user.id) }
    let(:channel) { double.as_null_object }

    before do
      Pusher.stub(:[]).with("private-user-#{user.id}") { channel }
      channel.stub(:trigger)
    end

    it "sends the user's N2O info as a serialized JSON object to the web app via Shover" do
      expect(Shover).to receive(:publish).with(user.id, 'aio:n2o_updated', { n2o: { max: user.max_n2o, used: user.used_n2o }})
      channel.should_receive(:trigger) do |message, data|
        message.should eq 'aio:n2o_updated'
        data.should eq({n2o: { max: user.max_n2o, used: user.used_n2o }})
      end

      job.perform
    end
  end

  describe '.submit_job' do
    let!(:user) { create :user }

    it 'should submit a delayed job' do
      expect {
        PushCurrentN2oBalanceJob.submit_job(user)
      }.to change(Delayed::Job, :count).by(1)

      Delayed::Job.last.handler.should match(/PushCurrentN2oBalanceJob.*?user_id: #{user.id}/m)
    end
  end
end


