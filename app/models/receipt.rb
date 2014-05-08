class Receipt < ActiveRecord::Base
  attr_accessible :period_start, :period_end, :lines, :subtotal, :total
  belongs_to :billing_profile

  serialize :lines, JSON

  scope :order_by_latest, -> { order('created_at DESC') }

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

  def plan_name
    if plan = lines.first["plan"]
      plan["name"]
    end
  end

  def first_line_description
    description = lines.first["description"]
  end
end
