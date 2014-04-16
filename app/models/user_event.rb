class UserEvent < ActiveRecord::Base
  belongs_to :user
  attr_accessible :user_id, :event
end
