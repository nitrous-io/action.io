class LinkedinUser
  NON_AUTHENTICATED_USER = Class.new

  # Returns an object that is capable of communicating with LinkedIn on behalf of
  # the user.
  #
  # user - instance of `User` model
  #
  # returns instance of `LinkedIn::Client` when user can interact with LinkedIn
  # If the user cannot interact with LinkedIn :(, then return `NON_AUTHENTICATED_USER`
  def self.init(user)
    linkedin_auth = user.authentications.find_by_provider(:linkedin)
    return NON_AUTHENTICATED_USER unless linkedin_auth.present?

    lnkd_client = LinkedIn::Client.new(Settings.linkedin_id, Settings.linkedin_secret)
    lnkd_client.authorize_from_access(linkedin_auth.token, linkedin_auth.secret)

    lnkd_client.profile(fields: %w(positions))
  end
end

