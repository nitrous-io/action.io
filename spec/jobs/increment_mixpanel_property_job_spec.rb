require 'spec_helper'

describe IncrementMixpanelPropertyJob do
  describe '#perform' do
    let!(:user)     { create :user, email: 'i@mclov.in', username: 'iamclovin', full_name: 'Mc Lovin' }
    let!(:mixpanel) { double('mixpanel') }

    before do
      Mixpanel::Tracker.stub(:new).and_return(mixpanel)
    end

    it "should identify the user and set some attributes" do
      mixpanel.should_receive(:increment).with('i@mclov.in', { boxes_created: 1 })
      IncrementMixpanelPropertyJob.new(user.id, :boxes_created, 1).perform
    end
  end

  describe ".submit_job" do
    let!(:user)     { create :user, email: 'i@mclov.in', username: 'iamclovin', full_name: 'Mc Lovin' }

    it "should submit a delayed job" do
      expect {
        IncrementMixpanelPropertyJob.submit_job(user.id, :boxes_created, 1)
      }.to change(Delayed::Job, :count).by(1)

      Delayed::Job.all[-1].handler.should =~ /IncrementMixpanelPropertyJob\nuser_id: #{user.id}\nproperty: :boxes_created\nvalue: 1/
    end
  end
end

