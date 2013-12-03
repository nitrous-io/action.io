class FetchUserCompanyJob < Job
  attr_accessor :user_id

  def initialize(user_id)
    self.user_id = user_id
  end

  def perform
    user = User.find(user_id)
    github_user = GithubUser.new(user)

    has_company = github_user.has_company? || user.has_linkedin_company?

    channel = Pusher["private-user-#{user_id}"]
    channel.trigger 'aio:fetch_user_company', has_company
  end
end
