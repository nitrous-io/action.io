class TwitterHandler
  class NotAuthenticatedError < RuntimeError; end
  attr_reader :user, :client

  def initialize(user)
    @user = user
    if authentication = @user.authentications.find_by_provider('twitter')
      @client = Twitter::Client.new(
        oauth_token: authentication.token,
        oauth_token_secret: authentication.secret
      )
    else
      raise NotAuthenticatedError
    end
  end

  def follow
    begin
      if self.client.follow("nitrousio")
        self.user.fill_n2o_for_twitter_follow!
      end
    rescue Twitter::Error::Unauthorized
      nil
    end
  end

  def tweet(message)
    begin
      if self.client.update(message)
        self.user.fill_n2o_for_tweet!
      end
    rescue Twitter::Error::Unauthorized
      nil
    end
  end

  def followers_count
    begin
      self.client.user.followers_count
    rescue Twitter::Error::Unauthorized
      nil
    end
  end

  def handle
    begin
      self.client.user.screen_name
    rescue Twitter::Error::Unauthorized
      nil
    end
  end
end
