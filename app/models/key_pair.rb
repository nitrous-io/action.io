class KeyPair < ActiveRecord::Base
  attr_accessible :private_key, :public_key
  belongs_to  :box
end
