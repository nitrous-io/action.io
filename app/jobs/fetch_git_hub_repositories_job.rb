class FetchGitHubRepositoriesJob < Job
  attr_accessor :user_id

  def initialize(user_id)
    self.user_id = user_id
  end

  def perform
    channel = Pusher["private-user-#{user_id}"]
    user = User.find(user_id)
    git_hub = GitHub.new(user)
    repositories = git_hub.repositories

    channel.trigger 'aio:fetch_repos', {
      status: 'ok',
      repositories: repositories
    }.to_json
  rescue Octokit::Error => error
    channel.trigger 'aio:fetch_repos', {
      status: 'fail',
      error: error.to_s
    }.to_json
  end
end
