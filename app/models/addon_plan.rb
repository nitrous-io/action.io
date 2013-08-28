class AddonPlan < ActiveRecord::Base
  belongs_to :addon
  has_many :addon_plan_benefits
end
