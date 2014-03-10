class Plan < ActiveRecord::Base
  has_many    :subscriptions
  has_many    :plan_group_memberships
  has_many    :plan_groups, through: :plan_group_memberships

  serialize   :features, Array

  attr_accessible :name, :price, :n2o_amount, :display_order, :features, :highlight, :interval, :stripe_id,
                  :cpu_multiplier, :vmem_multiplier, :memory, :storage

  scope :global, -> do
    plan_group = PlanGroup.find_by_name(PlanGroup::DEFAULT_NAME)
    if plan_group
      plan_group.plans
    else
      # Return an empty association
      Plan.where("id < 0")
    end
  end

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

  #FIXME remove once rake actionio:serialize_plan_features has been run on production
  def features
    case self[:features]
    when nil, ''
      []
    when 'Custom Domains'
      [{'name' => 'Custom Domains', 'live' => false}]
    else
      super
    end
  end
end
