class SubscriptionPlan < ActiveRecord::Base
  has_many :subscriptions

  attr_accessible :name, :price, :n2o_amount, :display_order, :features, :highlight, :interval, :stripe_id

  def description
    "#{name} ($#{'%.2f' % price} per #{interval})"
  end

  def price_as_currency
    "USD #{'%.2f' % price}"
  end
end
