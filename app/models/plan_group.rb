class PlanGroup < ActiveRecord::Base
  DEFAULT_NAME  = 'global'.freeze
  TEAM_NAME     = 'teams'.freeze
  N2O_NAME      = 'n2o'.freeze
  N2O_TEAM_NAME = 'n2o_teams'.freeze

  # plan group name to length of term in months
  AWS_ACTIVATE_TERMS = {
    'aws-activate-1mth' => 1,
    'aws-activate-3mth' => 3,
    'aws-activate-12mth' => 12,
  }.freeze

  attr_accessible :name

  validates_presence_of :name
  validates_uniqueness_of :name

  has_many  :users
  has_many  :plan_group_memberships
  has_many  :plans, through: :plan_group_memberships
end
