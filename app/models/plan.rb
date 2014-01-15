class Plan < ActiveRecord::Base
  has_many :subscriptions

  attr_accessible :name, :price, :n2o_amount, :display_order, :features, :highlight, :interval, :stripe_id,
                  :cpu_multiplier, :vmem_multiplier, :memory, :storage

  def description
    "#{name} ($#{'%.2f' % price} per #{interval})"
  end

  def price_as_currency
    "USD #{'%.2f' % price}"
  end

  def price_in_cents
    ( price * 100 ).round(2).to_i
  end

  def is_spec_downgrade_from(other)
    self.cpu_multiplier < other.cpu_multiplier || self.vmem_multiplier < other.vmem_multiplier
  end

  def is_price_downgrade_from(other)
    self.price < other.price
  end
end
