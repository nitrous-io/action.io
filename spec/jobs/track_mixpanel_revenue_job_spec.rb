require 'spec_helper'

describe TrackMixpanelRevenueJob do
  describe '#perform' do
    let!(:user)     { create :user, email: 'i@mclov.in', username: 'iamclovin', full_name: 'Mc Lovin', accepted_invites: 100 }
    let!(:mixpanel) { instance_double('Mixpanel::Tracker') }

    before do
      @bonus = user.bonus
      Timecop.freeze

      @now = Time.now
      Mixpanel::Tracker.stub(:new).and_return(mixpanel)
    end

    after do
      Timecop.return
    end

    it "should track the event with the user's email set as a default property" do
      expect(mixpanel).to receive(:track_charge).with('i@mclov.in', 19.99, @now, {})
      TrackMixpanelRevenueJob.new(user.id, 19.99).perform
    end

    it "should track the charge along with the mixpanel properties associated with the user if he has them" do
      user_profile = user.user_profile
      user_profile.mixpanel_properties = {"initial_referrer" => "$direct"}
      user_profile.save

      expect(mixpanel).to receive(:track_charge).with('i@mclov.in', 19.99, @now, "initial_referrer" => "$direct")
      TrackMixpanelRevenueJob.new(user.id, 19.99).perform
    end

    it "should track the charge along with the coupon code associated with the user if he has it" do
      coupon_code = 'doge'
      create :coupon, code: coupon_code
      user.update_attribute :coupon_code, coupon_code

      expect(mixpanel).to receive(:track_charge).with('i@mclov.in', 19.99, @now, "coupon_code" => coupon_code)
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

