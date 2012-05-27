class KeyPair < ActiveRecord::Base
  belongs_to  :box

  attr_accessible
end
