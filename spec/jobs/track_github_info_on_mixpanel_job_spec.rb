require 'spec_helper'

describe TrackGithubInfoOnMixpanelJob do
  let!(:user) { create :user }
  let(:github_user) { instance_double('GithubUser') }

  describe '#perform' do
    before { GithubUser.stub(:new).with(user) { github_user } }

    context 'when user has authenticated with GitHub' do
      let!(:mixpanel) { instance_double('Mixpanel::Tracker') }
      let(:profile) { double('profile') }

      before do
        Mixpanel::Tracker.stub(:new) { mixpanel }
        github_user.stub(:profile) { profile }

        profile.stub(:plan)                { { 'name' => 'small' } }
        profile.stub(:company)             { 'Nitrous.IO' }
        profile.stub(:public_repos)        { 42 }
        profile.stub(:followers)           { 420 }
        profile.stub(:following)           { 4200 }
        profile.stub(:public_gists)        { 42000 }
        profile.stub(:total_private_repos) { 24 }
        profile.stub(:owned_private_repos) { 240 }
        profile.stub(:private_gists)       { 2400 }
        profile.stub(:collaborators)       { 2 }
      end

      it "should track the user's GitHub user profile with their email" do
        expect(mixpanel).to receive(:set).with user.email,  'github_plan_name'           => 'small',
                                                            'github_company'             => 'Nitrous.IO',
                                                            'github_public_repos'        => 42,
                                                            'github_followers'           => 420,
                                                            'github_following'           => 4200,
                                                            'github_public_gists'        => 42000,
                                                            'github_total_private_repos' => 24,
                                                            'github_owned_private_repos' => 240,
                                                            'github_private_gists'       => 2400,
                                                            'github_collaborators'       => 2

        TrackGithubInfoOnMixpanelJob.new(user.id).perform
      end
    end

    context 'when user has not authenticated with GitHub' do
      before { github_user.stub(:profile) { nil } }

      it 'should not record to Mixpanel' do
        expect(Mixpanel::Tracker).not_to receive(:new)
        TrackGithubInfoOnMixpanelJob.new(user.id).perform
      end
    end
  end

  describe '.submit_job' do
    let!(:user) { create :user }

    it 'should submit a delayed job' do
      expect {
        TrackGithubInfoOnMixpanelJob.submit_job(user.id)
      }.to change(Delayed::Job, :count).by(1)

      expect(Delayed::Job.last.handler).to match(/TrackGithubInfoOnMixpanelJob.*?user_id: #{user.id}/m)
    end
  end
end
