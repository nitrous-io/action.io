class Receipt < ActiveRecord::Base
  attr_accessible :period_start, :period_end, :lines, :subtotal, :total
  belongs_to :billing_profile

  serialize :lines, JSON

  def period_start=(value)
    if value.is_a? Integer
      self[:period_start] = Time.at(value)
    end
  end

  def period_end=(value)
    if value.is_a? Integer
      self[:period_end] = Time.at(value)
    end
  end
end
