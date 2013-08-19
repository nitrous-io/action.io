module EncryptedAttributes
  def encrypted_attr_accessor(*syms)
    syms.each do |sym|
      class_eval("
        def #{sym}=(data)
          return if data.blank?

          iv, encrypted = ActionCipher.encrypt(Settings.aes_key, data)
          self.encrypted_#{sym} = encrypted
          self.encrypted_#{sym}_iv = iv
        end

        def #{sym}
          return unless self.encrypted_#{sym}
          ActionCipher.decrypt Settings.aes_key, self.encrypted_#{sym}_iv, self.encrypted_#{sym}
        end
      ")
    end
  end
end
