class AppliedDiscount < ActiveRecord::Base
  attr_accessible :percent_off, :amount_off, :stripe_customer_id, :started_at, :ended_at
end
