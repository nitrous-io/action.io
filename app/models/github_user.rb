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

    @client = Octokit::Client.new access_token: token
    begin
      @client.login
      @client
    rescue Octokit::Unauthorized
      @client = nil
    end
  end

  def authenticated?
    # If we have a client, we're already authenticated to GitHub.
    client.present?
  end

  def has_company?
    return false if !client
    client.user.company.present?
  end

  def profile
    return nil if !client
    client.user
  end

  def add_key(*args)
    # Delegate to Octokit::Client.
    client.try(:add_key, *args)
  end
end
