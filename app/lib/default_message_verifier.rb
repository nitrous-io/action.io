module DefaultMessageVerifier
  def self.verifier
    @@message_verifier ||= ActiveSupport::MessageVerifier.new Rails.application.config.secret_token, serializer: JSON
  end
end
