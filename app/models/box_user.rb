class BoxUser < ActiveRecord::Base
  belongs_to :box
  belongs_to :user

  attr_accessible
end
