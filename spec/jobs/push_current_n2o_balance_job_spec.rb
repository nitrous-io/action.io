require 'spec_helper'

describe PushCurrentN2oBalanceJob do
  describe '#perform' do
    let!(:user)   { create :user }
    let!(:job)    { PushCurrentN2oBalanceJob.new(user.id) }
    let(:channel) { stub.as_null_object }

    before do
      Pusher.stub(:[]).with("private-user-#{user.id}") { channel }
      channel.stub(:trigger)
    end

    it 'sends the current user as a serialized JSON object to the web app via Pusher' do
      channel.should_receive(:trigger) do |message, data|
        message.should eq 'aio:n2o_updated'
        data.should eq({n2o: { max: user.max_n2o, used: user.used_n2o }})
      end

      job.perform
    end
  end

  describe ".submit_job" do
    let!(:user)     { create :user }

    it "should submit a delayed job" do
      expect {
        PushCurrentN2oBalanceJob.submit_job(user)
      }.to change(Delayed::Job, :count).by(1)

      job_handler = Delayed::Job.all[-1].handler

      expect(job_handler).to match(/PushCurrentN2oBalanceJob.*?user_id: #{user.id}/m)
    end
  end
end


