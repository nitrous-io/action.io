class Plan < ActiveRecord::Base
  has_many :subscriptions
  has_many :users, through: :subscriptions
  attr_accessible :name, :description, :active, :price_cents, :num_boxes, :ram, :disk_space, :ssh_access, :sleepless

  def storage
    disk_space / 1024
  end

  def price
    ( price_cents / 100.0 ).round(2)
  end
end
