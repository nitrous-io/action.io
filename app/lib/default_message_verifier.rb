module DefaultMessageVerifier
  def self.verifier
    @@message_verifier ||= ActiveSupport::MessageVerifier.new ActionIO::Application.config.secret_token, serializer: JSON
  end
end
