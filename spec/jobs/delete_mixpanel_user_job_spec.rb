require 'spec_helper'

describe DeleteMixpanelUserJob do
  describe '#perform' do
    let!(:user)     { create :user }
    let!(:mixpanel) { double 'mixpanel' }

    before do
      Mixpanel::Tracker.stub(:new).and_return(mixpanel)
    end

    it "should delete the user from Mixpanel" do
      expect(mixpanel).to receive(:delete).with(user.email)
      DeleteMixpanelUserJob.new(user.email).perform
    end
  end

  describe ".submit_job" do
    let!(:user)     { create :user }

    it "should submit a delayed job" do
      expect {
        DeleteMixpanelUserJob.submit_job(user.email)
      }.to change(Delayed::Job, :count).by(1)

      job_handler = Delayed::Job.all[-1].handler

      expect(job_handler).to match(/DeleteMixpanelUserJob.*?email: #{user.email}/m)
    end
  end
end
