class BoxhostKeyPair < ActiveRecord::Base
  include PrivateKeyEncryptable

  belongs_to :boxhost

  def aes_key
    Settings.aes_key
  end
end
