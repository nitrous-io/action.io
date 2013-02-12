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

# == Schema Information
#
# Table name: key_pairs
#
#  id                       :integer          not null, primary key
#  box_id                   :integer          not null
#  public_key               :text             not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  encrypted_private_key    :text             not null
#  encrypted_private_key_iv :string(255)      not null
#
