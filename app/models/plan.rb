class Plan < ActiveRecord::Base
  has_many :subscriptions
  has_many :users, through: :subscriptions
  attr_accessible :name, :description, :active, :price_cents, :num_boxes, :ram, :disk_space, :ssh_access, :sleepless
end
