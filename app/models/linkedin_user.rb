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

  def profile(*args)
    client && client.profile(*args)
  rescue LinkedIn::Errors::UnauthorizedError
    return nil
  end

  def has_company?
    # See LinkedIn API docs: http://developer.linkedin.com/documents/profile-fields#fullprofile.
    p = profile(fields: %w(three-current-positions))
    return false unless p

    p['three_current_positions']['all'].present?
  end

  def positions
    p = profile(fields: %w(positions))
    return nil unless p

    p['positions']['all']
  end
end

