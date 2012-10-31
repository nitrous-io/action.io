module ActionCipher
  class << self
    def encrypt(key, data)
      aes = OpenSSL::Cipher.new('AES-256-CBC')
      aes.encrypt
      aes.key = Digest::SHA256.digest(key)
      iv = aes.random_iv
      aes.iv = iv
      encrypted = aes.update(data) + aes.final
      [Base64.encode64(iv), Base64.encode64(encrypted)]
    end

    def decrypt(key, iv, encrypted)
      iv = Base64.decode64 iv
      encrypted = Base64.decode64 encrypted
      aes = OpenSSL::Cipher.new('AES-256-CBC')
      aes.decrypt
      aes.key = Digest::SHA256.digest(key)
      aes.iv = iv
      aes.update(encrypted) + aes.final
    end
  end
end

