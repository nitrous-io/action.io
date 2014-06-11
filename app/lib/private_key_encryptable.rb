module PrivateKeyEncryptable
  def aes_key
    ''
  end

  def private_key=(data)
    iv, encrypted = ActionCipher.encrypt(self.aes_key, data)
    self.encrypted_private_key = encrypted
    self.encrypted_private_key_iv = iv
  end

  def private_key
    ActionCipher.decrypt self.aes_key, self.encrypted_private_key_iv, self.encrypted_private_key
  end
end
