class LinkedinUser
  attr_accessor :user

  def initialize(user=nil)
    @user = user
  end

  def client
    return @client if @client
    return nil if user.blank?
    linkedin_auth = user.authentications.find_by_provider(:linkedin)
    return nil if linkedin_auth.blank?

    @client = LinkedIn::Client.new(Settings.linkedin_id, Settings.linkedin_secret)
    @client.authorize_from_access(linkedin_auth.token, linkedin_auth.secret)
    @client
  end

  def has_company?
    # See LinkedIn API docs: http://developer.linkedin.com/documents/profile-fields#fullprofile.
    client && client.profile(fields: %w(three-current-positions))['three_current_positions']['all'].present?
  end

  def profile(*args)
    client && client.profile(*args)
  end

  def positions
    client && client.profile(fields: %w(positions))['positions']['all']
  end
end

