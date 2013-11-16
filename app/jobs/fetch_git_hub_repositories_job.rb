class FetchGitHubRepositoriesJob < Job
  attr_accessor :user_id

  def initialize(user_id)
    self.user_id = user_id
  end

  def perform
    user = User.find(user_id)
    repositories = user.repositories

    channel = Pusher["private-user-#{user_id}"]
    channel.trigger 'aio:fetch_repos', repositories.to_json
  end
end
