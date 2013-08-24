class TrackGithubInfoOnMixpanelJob < Job
  attr_accessor :user_id

  def initialize(user_id)
    self.user_id = user_id
  end

  def perform
    user = User.find user_id
    github_user = GithubUser.init(user).user

    if github_user
      mixpanel = Mixpanel::Tracker.new ENV['MIXPANEL_TOKEN']
      mixpanel.set user.email, 'github_plan_name'           => github_user.plan['name'],
                               'github_company'             => github_user.company,
                               'github_public_repos'        => github_user.public_repos,
                               'github_followers'           => github_user.followers,
                               'github_following'           => github_user.following,
                               'github_public_gists'        => github_user.public_gists,
                               'github_total_private_repos' => github_user.total_private_repos,
                               'github_owned_private_repos' => github_user.owned_private_repos,
                               'github_private_gists'       => github_user.private_gists,
                               'github_collaborators'       => github_user.collaborators
    end
  end

  def self.submit_job(user_id)
    Delayed::Job.enqueue(self.new(user_id))
  end
end

