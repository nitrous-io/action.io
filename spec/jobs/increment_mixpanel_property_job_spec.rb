require 'spec_helper'

describe IncrementMixpanelPropertyJob do
  describe '#perform' do
    let!(:user)     { create :user, email: 'i@mclov.in', username: 'iamclovin', full_name: 'Mc Lovin' }
    let!(:mixpanel) { double('mixpanel') }

    before do
      Mixpanel::Tracker.stub(:new).and_return(mixpanel)
    end

    it "should identify the user and set some attributes" do
      expect(mixpanel).to receive(:increment).with('i@mclov.in', { boxes_created: 1 })
      IncrementMixpanelPropertyJob.new(user.id, :boxes_created, 1).perform
    end
  end

  describe ".submit_job" do
    let!(:user)     { create :user, email: 'i@mclov.in', username: 'iamclovin', full_name: 'Mc Lovin' }

    it "should submit a delayed job" do
      expect {
        IncrementMixpanelPropertyJob.submit_job(user.id, :boxes_created, 1)
      }.to change(Delayed::Job, :count).by(1)

      job_handler = Delayed::Job.all[-1].handler

      expect(job_handler).to match /IncrementMixpanelPropertyJob.*?user_id: #{user.id}/m
      expect(job_handler).to match /IncrementMixpanelPropertyJob.*?property: :boxes_created/m
      expect(job_handler).to match /IncrementMixpanelPropertyJob.*?value: 1/m
    end
  end
end

