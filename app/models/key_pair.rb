class KeyPair < ActiveRecord::Base
  include PrivateKeyEncryptable

  belongs_to :box

  def aes_key
    Settings.aes_key
  end
end
