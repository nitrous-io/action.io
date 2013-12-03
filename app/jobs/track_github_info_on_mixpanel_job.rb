class TrackGithubInfoOnMixpanelJob < Job
  attr_accessor :user_id

  def initialize(user_id)
    self.user_id = user_id
  end

  def perform
    user = User.find user_id
    github_user = GithubUser.new(user)
    profile = github_user.profile
    return if !profile

    mixpanel = Mixpanel::Tracker.new ENV['MIXPANEL_TOKEN']
    mixpanel.set user.email, 'github_plan_name'           => profile.plan['name'],
                             'github_company'             => profile.company,
                             'github_public_repos'        => profile.public_repos,
                             'github_followers'           => profile.followers,
                             'github_following'           => profile.following,
                             'github_public_gists'        => profile.public_gists,
                             'github_total_private_repos' => profile.total_private_repos,
                             'github_owned_private_repos' => profile.owned_private_repos,
                             'github_private_gists'       => profile.private_gists,
                             'github_collaborators'       => profile.collaborators
  end

  def self.submit_job(user_id)
    Delayed::Job.enqueue(self.new(user_id))
  end
end

