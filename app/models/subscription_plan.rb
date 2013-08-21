class SubscriptionPlan < ActiveRecord::Base
  has_many :subscriptions

  attr_accessible :name, :price, :display_order, :features, :highlight, :interval, :stripe_id
end
