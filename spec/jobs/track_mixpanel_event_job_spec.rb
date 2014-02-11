require 'spec_helper'

describe TrackMixpanelEventJob do
  describe '#perform' do
    let!(:user)     { create :user, email: 'i@mclov.in', username: 'iamclovin', full_name: 'Mc Lovin', accepted_invites: 100 }
    let!(:mixpanel) { instance_double('Mixpanel::Tracker') }

    before do
      @bonus = user.bonus
      Mixpanel::Tracker.stub(:new).and_return(mixpanel)
    end

    context 'with an active user account' do
      it "should track the event with the user's email set as a default property" do
        expect(mixpanel).to receive(:track).with('Box Created', email: 'i@mclov.in',
                                                                distinct_id: 'i@mclov.in',
                                                                free_n2o: user.free_n2o,
                                                                is_github_authenticated: @bonus.github.present?,
                                                                is_twitter_authenticated: @bonus.twitter.present?,
                                                                is_facebook_authenticated: @bonus.facebook.present?,
                                                                is_google_authenticated: @bonus.google.present?,
                                                                is_linkedin_authenticated: @bonus.linkedin.present?,
                                                                invited_friends: @bonus.invite_friends.present?,
                                                                twitter_follow: @bonus.twitter_follow.present?,
                                                                tweet_sent: @bonus.tweet_sent.present?,
                                                                accepted_invites: 100,
                                                                paid_user: false)

        TrackMixpanelEventJob.new('Box Created', user.id).perform
      end

      it "should track the event with the user's email set as a default property along with other properties passed" do
        expect(mixpanel).to receive(:track).with('Box Created', email: 'i@mclov.in',
                                                                distinct_id: 'i@mclov.in',
                                                                free_n2o: user.free_n2o,
                                                                is_github_authenticated: @bonus.github.present?,
                                                                is_twitter_authenticated: @bonus.twitter.present?,
                                                                is_facebook_authenticated: @bonus.facebook.present?,
                                                                is_google_authenticated: @bonus.google.present?,
                                                                is_linkedin_authenticated: @bonus.linkedin.present?,
                                                                invited_friends: @bonus.invite_friends.present?,
                                                                twitter_follow: @bonus.twitter_follow.present?,
                                                                tweet_sent: @bonus.tweet_sent.present?,
                                                                accepted_invites: 100,
                                                                paid_user: false,
                                                                box_id: 1)

        TrackMixpanelEventJob.new('Box Created', user.id, { box_id: 1 }).perform
      end

      context 'when user has mixpanel properties set' do
        before do
          profile = user.user_profile
          profile.mixpanel_properties = {'initial_referrer' => '$direct', 'utm_source' => 'twitter'}
          profile.save
        end

        it "should track the event with the user's email set as a default property along with mixpanel properties stored as part of the user's profile" do
          expect(mixpanel).to receive(:track).with('Box Created', email: 'i@mclov.in',
                                                                  distinct_id: 'i@mclov.in',
                                                                  free_n2o: user.free_n2o,
                                                                  is_github_authenticated: @bonus.github.present?,
                                                                  is_twitter_authenticated: @bonus.twitter.present?,
                                                                  is_facebook_authenticated: @bonus.facebook.present?,
                                                                  is_google_authenticated: @bonus.google.present?,
                                                                  is_linkedin_authenticated: @bonus.linkedin.present?,
                                                                  invited_friends: @bonus.invite_friends.present?,
                                                                  twitter_follow: @bonus.twitter_follow.present?,
                                                                  tweet_sent: @bonus.tweet_sent.present?,
                                                                  accepted_invites: 100,
                                                                  paid_user: false,
                                                                  'initial_referrer' => '$direct',
                                                                  'utm_source' => 'twitter')

          TrackMixpanelEventJob.new('Box Created', user.id).perform
        end

        it "should track the event with the user's email set as a default property along with the coupon code associated with the user" do
          coupon_code = 'doge'
          create :coupon, code: coupon_code
          user.update_attribute :coupon_code, coupon_code

          expect(mixpanel).to receive(:track).with('Box Created', email: 'i@mclov.in',
                                                                  distinct_id: 'i@mclov.in',
                                                                  free_n2o: user.free_n2o,
                                                                  is_github_authenticated: @bonus.github.present?,
                                                                  is_twitter_authenticated: @bonus.twitter.present?,
                                                                  is_facebook_authenticated: @bonus.facebook.present?,
                                                                  is_google_authenticated: @bonus.google.present?,
                                                                  is_linkedin_authenticated: @bonus.linkedin.present?,
                                                                  invited_friends: @bonus.invite_friends.present?,
                                                                  twitter_follow: @bonus.twitter_follow.present?,
                                                                  tweet_sent: @bonus.tweet_sent.present?,
                                                                  accepted_invites: 100,
                                                                  paid_user: false,
                                                                  'initial_referrer' => '$direct',
                                                                  'utm_source' => 'twitter',
                                                                  'coupon_code' => 'doge')

          TrackMixpanelEventJob.new('Box Created', user.id).perform
        end
      end

      context 'when user is a paid user' do
        let!(:plan) { create :plan }

        before do
          profile = user.user_profile
          profile.mixpanel_properties = {'initial_referrer' => '$direct', 'utm_source' => 'twitter'}
          profile.save

          User.any_instance.stub(:active_plan).and_return plan
        end

        it "should track the event with the user's email set as a default property along with mixpanel properties stored as part of the user's profile" do
          expect(mixpanel).to receive(:track).with('Box Created', email: 'i@mclov.in',
                                                                  distinct_id: 'i@mclov.in',
                                                                  free_n2o: user.free_n2o,
                                                                  is_github_authenticated: @bonus.github.present?,
                                                                  is_twitter_authenticated: @bonus.twitter.present?,
                                                                  is_facebook_authenticated: @bonus.facebook.present?,
                                                                  is_google_authenticated: @bonus.google.present?,
                                                                  is_linkedin_authenticated: @bonus.linkedin.present?,
                                                                  invited_friends: @bonus.invite_friends.present?,
                                                                  twitter_follow: @bonus.twitter_follow.present?,
                                                                  tweet_sent: @bonus.tweet_sent.present?,
                                                                  accepted_invites: 100,
                                                                  paid_user: true,
                                                                  'initial_referrer' => '$direct',
                                                                  'utm_source' => 'twitter')

          TrackMixpanelEventJob.new('Box Created', user.id).perform
        end
      end
    end

    context 'with a deleted user account' do
      let!(:deleted_user)  { create :user, email: 'del@nit.io' }

      before do
        deleted_user.destroy
      end

      it "should track the event with the deleted user's email set as a default property" do
        expect(mixpanel).to receive(:track).with('Deleted Account', email: 'del@nit.io', distinct_id: 'del@nit.io', foo: 'bar')
        TrackMixpanelEventJob.new('Deleted Account', deleted_user.id, { foo: 'bar' }).perform
      end
    end
  end

  describe ".submit_job" do
    let!(:user)     { create :user, email: 'i@mclov.in', username: 'iamclovin', full_name: 'Mc Lovin' }

    it "should submit a delayed job" do
      expect {
        TrackMixpanelEventJob.submit_job('Box Created', user.id)
      }.to change(Delayed::Job, :count).by(1)

      job_handler = Delayed::Job.all[-1].handler

      expect(job_handler).to match /TrackMixpanelEventJob.*?event: Box Created/m
      expect(job_handler).to match /TrackMixpanelEventJob.*?user_id: #{user.id}/m
    end
  end
end


