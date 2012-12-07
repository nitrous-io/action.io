module SignInToken
  EXPIRY = 5.minutes

  # if expiry_time is not given, it uses current_time + EXPIRY
  def self.generate(user, expiry_time=nil)
    Base64.urlsafe_encode64 DefaultMessageVerifier.verifier.generate(
      [user.id, (expiry_time || (Time.now + 5.minutes)).to_i]
    )
  end

  # verifies sign in token and returns a user object if valid
  def self.verify(token)
    token = Base64.urlsafe_decode64 token
    begin
      token_content = DefaultMessageVerifier.verifier.verify(token)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    else
      user_id = token_content[0]
      expiry_time = token_content[1]
      if Time.now < Time.at(expiry_time)
        User.find_by_id(user_id)
      end
    end
  end
end
