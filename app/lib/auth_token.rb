module AuthToken
  EXPIRY = 5.minutes

  # if expiry_time is not given, it uses current_time + EXPIRY
  def self.generate(user, name, expiry_time=nil)
    expiry_time = (expiry_time || Time.now + 5.minutes).to_i
    content = [user.id, name, expiry_time]
    Base64.urlsafe_encode64 DefaultMessageVerifier.verifier.generate(content)
  end

  # verifies sign in token and returns a user object if valid
  def self.verify(token, name_given)
    token = Base64.urlsafe_decode64 token
    begin
      token_content = DefaultMessageVerifier.verifier.verify(token)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    else
      user_id, name, expiry_time = token_content
      if (Time.now < Time.at(expiry_time)) && (name == name_given)
        User.find_by_id(user_id)
      end
    end
  end
end
