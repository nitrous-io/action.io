require 'spec_helper'

describe TrackGithubInfoOnMixpanelJob do
  describe '#perform' do
    let!(:user)             { create :user }
    let!(:mixpanel)         { double('mixpanel') }
    let!(:octokit)          { double('octokit') }
    let!(:github_user)      { double('github_user') }

    before do
      Mixpanel::Tracker.stub(:new).and_return(mixpanel)
      GithubUser.stub(:init).and_return(octokit)
      octokit.stub!(:user).and_return(github_user)

      github_user.stub!(:plan)                { { "name" => "small" } }
      github_user.stub!(:company)             { 'Nitrous.IO' }
      github_user.stub!(:public_repos)        { 42 }
      github_user.stub!(:followers)           { 420 }
      github_user.stub!(:following)           { 4200 }
      github_user.stub!(:public_gists)        { 42000 }
      github_user.stub!(:total_private_repos) { 24 }
      github_user.stub!(:owned_private_repos) { 240 }
      github_user.stub!(:private_gists)       { 2400 }
      github_user.stub!(:collaborators)       { 2 }
    end

    it "should track Github info with the user's email" do
      mixpanel.should_receive(:set).with user.email, 'github_plan_name'           => 'small',
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

  describe ".submit_job" do
    let!(:user)     { create :user }

    it "should submit a delayed job" do
      expect {
        TrackGithubInfoOnMixpanelJob.submit_job(user.id)
      }.to change(Delayed::Job, :count).by(1)

      job_handler = Delayed::Job.all[-1].handler

      expect(job_handler).to match(/TrackGithubInfoOnMixpanelJob.*?user_id: #{user.id}/m)
    end
  end
end


