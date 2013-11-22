require 'spec_helper'

describe TrackMixpanelRevenueJob do
  describe '#perform' do
    let!(:user)     { create :user, email: 'i@mclov.in', username: 'iamclovin', full_name: 'Mc Lovin', accepted_invites: 100 }
    let!(:mixpanel) { double('mixpanel') }

    before do
      @bonus = user.bonus
      Mixpanel::Tracker.stub(:new).and_return(mixpanel)
    end

    it "should track the event with the user's email set as a default property" do
      mixpanel.should_receive(:track_charge).with('i@mclov.in', 19.99)
      TrackMixpanelRevenueJob.new(user.id, 19.99).perform
    end
  end

  describe ".submit_job" do
    let!(:user)     { create :user, email: 'i@mclov.in', username: 'iamclovin', full_name: 'Mc Lovin' }

    it "should submit a delayed job" do
      expect {
        TrackMixpanelRevenueJob.submit_job(user.id, 19.99)
      }.to change(Delayed::Job, :count).by(1)

      job_handler = Delayed::Job.all[-1].handler

      expect(job_handler).to match(/TrackMixpanelRevenueJob.*?amount: 19\.99/m)
      expect(job_handler).to match(/TrackMixpanelRevenueJob.*?user_id: #{user.id}/m)
    end
  end
end

