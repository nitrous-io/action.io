class KeyPair < ActiveRecord::Base
  extend EncryptedAttributes

  encrypted_attr_accessor :private_key
  belongs_to :box
end

