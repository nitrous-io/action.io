class GithubUser
  attr_accessor :user

  def initialize(user=nil)
    @user = user
  end

  def client
    return @client if @client
    return nil if user.blank?
    token = user.token_for(:github)
    return nil if token.blank?

    @client = Octokit::Client.new oauth_token: token
  end

  def authenticated?
    client && client.authenticated?
  end

  def has_company?
    return false if client.blank?

    client.user.company.present?
  end

  def profile
    return nil if client.blank?

    client.user
  end

  def add_key(*args)
    # Delegate to Octokit::Client.
    client.try(:add_key, *args)
  end
end
