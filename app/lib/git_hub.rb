class GitHub
  attr_accessor :user

  def initialize(user=nil)
    @user = user
  end

  def client
    return @client if @client
    return nil if user.blank?
    access_token = user.token_for(:github)
    return nil if access_token.blank?

    @client = Octokit::Client.new access_token: access_token
  end

  # We only get public repos from GitHub now because we only ask for the
  # 'public_repo' scope (see http://developer.github.com/v3/oauth/#scopes).
  def repositories
    return [] if user.blank? || client.blank?

    # TODO Get user's N organizations' public repos as well - not doing it now
    # because it requires N + 1 API calls.
    user_repos = client.repos
    member_repos = client.repos nil, type: 'member'

    all_repos = (user_repos + member_repos).map { |github_repo| repository_for(github_repo) }

    @repositories = all_repos
  end

  def repository_for(github_repo)
    Repository.new(
      id: github_repo.id,
      name: github_repo.name,
      full_name: github_repo.full_name,
      private: github_repo.private,
      html_url: github_repo.rels[:html].href,
      clone_url: github_repo.rels[:clone].href,
      git_url: github_repo.rels[:git].href,
      ssh_url: github_repo.rels[:ssh].href
    )
  end
end
