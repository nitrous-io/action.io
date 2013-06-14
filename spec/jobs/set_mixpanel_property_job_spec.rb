require 'spec_helper'

describe SetMixpanelPropertyJob do
  describe '#perform' do
    let!(:user)     { create :user, email: 'i@mclov.in', username: 'iamclovin', full_name: 'Mc Lovin' }
    let!(:mixpanel) { double('mixpanel') }

    before do
      Mixpanel::Tracker.stub(:new).and_return(mixpanel)
    end

    it "should identify the user and set some attributes" do
      mixpanel.should_receive(:set).with('i@mclov.in', { is_github_authenticated: true })
      SetMixpanelPropertyJob.new(user.id, :is_github_authenticated, true).perform
    end
  end

  describe ".submit_job" do
    let!(:user)     { create :user, email: 'i@mclov.in', username: 'iamclovin', full_name: 'Mc Lovin' }

    it "should submit a delayed job" do
      expect {
        SetMixpanelPropertyJob.submit_job(user.id, :is_github_authenticated, true)
      }.to change(Delayed::Job, :count).by(1)

      job_handler = Delayed::Job.all[-1].handler

      expect(job_handler).to match /SetMixpanelPropertyJob.*?user_id: #{user.id}/m
      expect(job_handler).to match /SetMixpanelPropertyJob.*?property: :is_github_authenticated/m
      expect(job_handler).to match /SetMixpanelPropertyJob.*?value: true/m
    end
  end
end


