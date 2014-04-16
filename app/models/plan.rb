class Plan < ActiveRecord::Base
  has_many    :subscriptions
  has_many    :plan_group_memberships
  has_many    :plan_groups, through: :plan_group_memberships

  serialize   :features, Array

  attr_accessible :name, :price, :n2o_amount, :display_order, :features, :highlight, :interval, :stripe_id,
                  :cpu_multiplier, :vmem_multiplier, :memory, :storage

  FEATURE_CUSTOM_DOMAINS = 'Custom Domains'
  FEATURE_BOX_SNAPSHOTS = 'Box Snapshots'

  scope :for_plan_group, -> (name) { joins(:plan_groups).where('plan_groups.name = ?', name) }
  scope :for_default_plan_group, -> { for_plan_group(PlanGroup::DEFAULT_NAME) }

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

  def has_feature?(feature_name)
    features.any? {|feature| feature['name'] == feature_name && feature['live'] == true }
  end

  # counts the number of subscriptions created (and still unchurned)
  # within the given period
  def subscriptions_count(period_start, period_end)
    period_start = period_start.beginning_of_day
    period_end = period_end.end_of_day
    subscriptions.where("state IN ('active', 'delinquent') AND created_at >= ? AND created_at <= ?", period_start, period_end).count
  end

  def trial_months
    return 0 if trial_period_days.blank?
    # only need below to be accurate for 31, 93, 365 days
    case trial_period_days
    when (1..31)
      1
    when 365
      12
    else
      (trial_period_days / 31)
    end
  end
end
