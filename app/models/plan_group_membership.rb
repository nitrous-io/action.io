class PlanGroupMembership < ActiveRecord::Base
  belongs_to  :plan_group
  belongs_to  :plan

  attr_accessible
end
