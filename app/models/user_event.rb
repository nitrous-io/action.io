class UserEvent < ActiveRecord::Base
  BANNED = 'banned'

  belongs_to :user
  attr_accessible :user_id, :event
end
