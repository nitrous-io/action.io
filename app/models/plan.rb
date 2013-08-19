class Plan < ActiveRecord::Base
  belongs_to :user
  belongs_to :coupon
  has_many :subscriptions

  attr_accessible :display_order, :features, :highlight, :interval, :name, :price, :stripe_id
end
