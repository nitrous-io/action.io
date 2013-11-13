class GithubUser
  NON_AUTHENTICATED_USER = Class.new

  # Returns an object that is capable of communicating with Github on behalf of
  # the user.
  #
  # user - instance of `User` model
  #
  # returns instance of `Octokit::Client` when user can interact with github
  # If the user cannot interact with Github :(, then return `NON_AUTHENTICATED_USER`
  def self.init(user)
    github_token = user.token_for(:github)
    return NON_AUTHENTICATED_USER unless github_token.present?
    Octokit::Client.new access_token: github_token
  end
end
