require 'spec_helper'

describe TrackMixpanelEventJob do
  describe '#perform' do
    let!(:user)     { create :user, email: 'i@mclov.in', username: 'iamclovin', full_name: 'Mc Lovin' }
    let!(:mixpanel) { double('mixpanel') }

    before do
      Mixpanel::Tracker.stub(:new).and_return(mixpanel)
    end

    it "should track the event with the user's email set as a default property" do
      mixpanel.should_receive(:track).with('Box Created', { email: 'i@mclov.in' })
      TrackMixpanelEventJob.new('Box Created', user.id).perform
    end

    it "should track the event with the user's email set as a default property along with other properties passed" do
      mixpanel.should_receive(:track).with('Box Created', { email: 'i@mclov.in', box_id: 1 })
      TrackMixpanelEventJob.new('Box Created', user.id, { box_id: 1 }).perform
    end
  end

  describe ".submit_job" do
    let!(:user)     { create :user, email: 'i@mclov.in', username: 'iamclovin', full_name: 'Mc Lovin' }

    it "should submit a delayed job" do
      expect {
        TrackMixpanelEventJob.submit_job('Box Created', user.id)
      }.to change(Delayed::Job, :count).by(1)

      Delayed::Job.all[-1].handler.should =~ /TrackMixpanelEventJob\nevent: Box Created\nuser_id: #{user.id}/
    end
  end
end


