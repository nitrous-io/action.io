class Subscription < ActiveRecord::Base
  include Koudoku::Subscription

  attr_accessible :card_type, :current_price, :last_four, :stripe_id

  belongs_to :user
  belongs_to :coupon
end
