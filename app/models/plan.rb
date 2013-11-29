class Plan < ActiveRecord::Base
  has_many :subscriptions

  attr_accessible :name, :price, :n2o_amount, :display_order, :features, :highlight, :interval, :stripe_id,
                  :cpu_multiplier, :vmem_multiplier

  def description
    "#{name} ($#{'%.2f' % price} per #{interval})"
  end

  def price_as_currency
    "USD #{'%.2f' % price}"
  end

  def is_downgrade_from(other)
    self.cpu_multiplier < other.cpu_multiplier || self.vmem_multiplier < other.vmem_multiplier
  end
end
