require 'spec_helper'

describe SendTerminationNoticeJob do
  let!(:user) { create :user }
  let!(:box) { create :box, owner: user }

  describe '#perform' do
    before do
      Timecop.freeze
      @now = Time.now
    end

    after do
      Timecop.return
    end

    it "should update the box's termination_notice_sent_at to the current time" do
      allow(UserMailer).to receive(:box_termination_notice) { double.as_null_object }
      allow(TrackMixpanelEventJob).to receive(:submit_job)

      SendTerminationNoticeJob.new(box.id).perform
      expect(box.reload.termination_notice_sent_at.to_i).to eq(@now.to_i)
    end

    it "should deliver a box termination notice to the box's owner" do
      allow(TrackMixpanelEventJob).to receive(:submit_job)

      expect(UserMailer).to receive(:box_termination_notice).with(user.id) { double.as_null_object }
      SendTerminationNoticeJob.new(box.id).perform
    end

    it "should track a Mixpanel event" do
      allow(UserMailer).to receive(:box_termination_notice) { double.as_null_object }

      expect(TrackMixpanelEventJob).to receive(:submit_job).with('Box Termination Notice Sent', user.id, hash_including(box_id: box.id))
      SendTerminationNoticeJob.new(box.id).perform
    end
  end

  describe '.submit_job' do
    it 'should submit a delayed job to send a termination notice' do
      expect {
        SendTerminationNoticeJob.submit_job(123)
      }.to change(Delayed::Job, :count).by(1)

      expect(Delayed::Job.last.handler).to match(/SendTerminationNoticeJob/)
      expect(Delayed::Job.last.handler).to match(/box_id: 123/)
    end
  end
end
