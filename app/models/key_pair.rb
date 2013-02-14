class KeyPair < ActiveRecord::Base
  belongs_to :box

  attr_accessible

  def private_key=(data)
    iv, encrypted = ActionCipher.encrypt(Settings.aes_key, data)
    self.encrypted_private_key = encrypted
    self.encrypted_private_key_iv = iv
  end

  def private_key
    ActionCipher.decrypt Settings.aes_key, self.encrypted_private_key_iv, self.encrypted_private_key
  end
end

