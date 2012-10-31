class AddEncryptedPrivateKeyAndEncryptedPrivateKeyIvInKeyPairs < ActiveRecord::Migration
  def up
    add_column :key_pairs, :encrypted_private_key, :text
    add_column :key_pairs, :encrypted_private_key_iv, :string

    key = Settings.aes_key
    raise 'AES_KEY not defined!' if key.blank?

    KeyPair.all.each do |key_pair|
      private_key = key_pair.attributes['private_key']
      iv, encrypted = ActionCipher.encrypt(key, private_key)
      key_pair.encrypted_private_key = encrypted
      key_pair.encrypted_private_key_iv = iv
      key_pair.save!
    end

    change_column :key_pairs, :encrypted_private_key, :text, null: false
    change_column :key_pairs, :encrypted_private_key_iv, :string, null: false
  end

  def down
    remove_column :key_pairs, :encrypted_private_key_iv
    remove_column :key_pairs, :encrypted_private_key
  end
end
