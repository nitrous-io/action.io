class TrackGithubInfoOnMixpanelJob < Job
  attr_accessor :user_id

  def initialize(user_id)
    self.user_id = user_id
  end

  def perform
    user = User.find user_id
    github_user = GithubUser.init(user)
    return if github_user == GithubUser::NON_AUTHENTICATED_USER

    user_details = github_user.user
    mixpanel = Mixpanel::Tracker.new ENV['MIXPANEL_TOKEN']
    mixpanel.set user.email, 'github_plan_name'           => user_details.plan['name'],
                             'github_company'             => user_details.company,
                             'github_public_repos'        => user_details.public_repos,
                             'github_followers'           => user_details.followers,
                             'github_following'           => user_details.following,
                             'github_public_gists'        => user_details.public_gists,
                             'github_total_private_repos' => user_details.total_private_repos,
                             'github_owned_private_repos' => user_details.owned_private_repos,
                             'github_private_gists'       => user_details.private_gists,
                             'github_collaborators'       => user_details.collaborators
  end

  def self.submit_job(user_id)
    Delayed::Job.enqueue(self.new(user_id))
  end
end

