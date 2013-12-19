require 'spec_helper'

describe IdentifyMixpanelUserJob do
  describe '#perform' do
    let!(:user)     { create :user, email: 'i@mclov.in', username: 'iamclovin', full_name: 'Mc Lovin' }
    let!(:mixpanel) { double('mixpanel') }

    before do
      Mixpanel::Tracker.stub(:new).and_return(mixpanel)
    end

    context "user has not created anything: boxes, public keys, etc" do
      it "should identify the user and set some attributes" do
        expect(mixpanel).to receive(:set).with('i@mclov.in',
                                           {
                                             email: 'i@mclov.in',
                                             username: 'iamclovin',
                                             created: user.created_at.as_json,
                                             ip: user.current_sign_in_ip,
                                             name: 'Mc Lovin',
                                             is_github_authenticated: false,
                                             boxes_created: 0,
                                             boxes_running: 0,
                                             public_keys: 0
                                           })

        IdentifyMixpanelUserJob.new(user.id).perform
      end
    end

    context "mixpanel attributes have been passed, including an old_distinct_id" do
      it "should identify the user and alias him as well" do
        expect(mixpanel).to receive(:alias).with 'i@mclov.in', distinct_id: 'old_distinct_id'
        expect(mixpanel).to receive(:set).with('i@mclov.in',
                                           {
                                             email: 'i@mclov.in',
                                             username: 'iamclovin',
                                             created: user.created_at.as_json,
                                             ip: user.current_sign_in_ip,
                                             name: 'Mc Lovin',
                                             is_github_authenticated: false,
                                             boxes_created: 0,
                                             boxes_running: 0,
                                             public_keys: 0,
                                             :$initial_referrer => "$direct"
                                           })

        IdentifyMixpanelUserJob.new(user.id, distinct_id: "old_distinct_id", :$initial_referrer => "$direct").perform
      end

    end

    context "user has a few boxes" do
      before do
        create :box, owner: user, state: 'running'
        create :box, owner: user, state: 'running'
        create :box, owner: user, terminated_at: 30.minutes.ago, state: 'stopped'
        create :box, owner: user, terminated_at: 2.days.ago, state: 'terminated'
      end

      it "should identify the user and set some attributes (including box counts)" do
        expect(mixpanel).to receive(:set).with('i@mclov.in',
                                           {
                                             email: 'i@mclov.in',
                                             username: 'iamclovin',
                                             created: user.created_at.as_json,
                                             ip: user.current_sign_in_ip,
                                             name: 'Mc Lovin',
                                             is_github_authenticated: false,
                                             boxes_created: 3,
                                             boxes_running: 2,
                                             public_keys: 0
                                           })

        IdentifyMixpanelUserJob.new(user.id).perform
      end
    end
  end

  describe ".submit_job" do
    let!(:user)     { create :user, email: 'i@mclov.in', username: 'iamclovin', full_name: 'Mc Lovin' }

    it "should submit a delayed job" do
      expect {
        IdentifyMixpanelUserJob.submit_job(user.id)
      }.to change(Delayed::Job, :count).by(1)

      expect(Delayed::Job.all[-1].handler).to match(/IdentifyMixpanelUserJob.*?user_id: #{user.id}/m)
    end
  end
end
