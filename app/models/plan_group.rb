class PlanGroup < ActiveRecord::Base
  attr_accessible :name

  validates_presence_of :name
  validates_uniqueness_of :name

  has_many  :users
  has_many  :plan_group_memberships
  has_many  :plans, through: :plan_group_memberships
end
