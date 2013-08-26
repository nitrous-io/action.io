class Receipt < ActiveRecord::Base
  attr_accessible :period_start, :period_end, :lines, :subtotal. :total
  belongs_to :billing_profile

  serialize :lines, JSON
end
