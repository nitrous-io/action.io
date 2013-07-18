class UserProfile < ActiveRecord::Base
  belongs_to :user
  attr_accessible :subscribed_to_newsletter
end
