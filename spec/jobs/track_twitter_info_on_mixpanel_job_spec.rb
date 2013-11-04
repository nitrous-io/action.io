require 'spec_helper'

describe TrackTwitterInfoOnMixpanelJob do
  describe '#perform' do
    let!(:user)             { create :user }
    let!(:mixpanel)         { double('mixpanel') }
    let!(:twitter_handler)  { double('twitter_handler') }

    before do
      @bonus = user.bonus
      Mixpanel::Tracker.stub(:new).and_return(mixpanel)
      TwitterHandler.stub(:new).and_return(twitter_handler)

      twitter_handler.stub(:followers_count) { 42 }
      twitter_handler.stub(:handle) { 'twitterati' }
    end

    it "should track the event with the user's email set as a default property" do
      mixpanel.should_receive(:set).with(user.email, 'twitter_handle' => 'twitterati', 'twitter_followers' => 42)

      TrackTwitterInfoOnMixpanelJob.new(user.id).perform
    end
  end

  describe ".submit_job" do
    let!(:user)     { create :user }

    it "should submit a delayed job" do
      expect {
        TrackTwitterInfoOnMixpanelJob.submit_job(user.id)
      }.to change(Delayed::Job, :count).by(1)

      job_handler = Delayed::Job.all[-1].handler

      expect(job_handler).to match(/TrackTwitterInfoOnMixpanelJob.*?user_id: #{user.id}/m)
    end
  end
end

