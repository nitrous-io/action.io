class WebAppController < ApplicationController
  before_filter :authenticate_user!

  layout 'basic'

  def index
    @boxes = current_user.visible_boxes
    @snapshots = current_user.snapshots.undeleted
    @public_keys = current_user.public_keys
    @regions = Region.enabled
    @box_templates = BoxTemplate.all
    @n2o_128mb_memory = KeyValue[N2oAllocation::N2O_128MB_MEMORY]
    @n2o_250mb_storage = KeyValue[N2oAllocation::N2O_250MB_STORAGE]
    @bonus = current_user.bonus
    @bonus_info = Bonus.bonus_info
    @coupon_code = cookies.delete(:coupon_code)

    @min_memory_in_mb = KeyValue[Box::N2O_MIN_MEMORY_MB]
    @min_storage_in_mb = KeyValue[Box::N2O_MIN_STORAGE_MB]
    @max_memory_in_mb = KeyValue[Box::N2O_MAX_MEMORY_MB]
    @max_storage_in_mb = KeyValue[Box::N2O_MAX_STORAGE_MB]

    if (plan_group = current_user.plan_group).nil?
      @personal_plans = Plan.global
    else
      @personal_plans = plan_group.plans
    end

    if(team_plans_group = PlanGroup.find_by_name(PlanGroup::TEAM_NAME)) && current_user.team_plans_enabled?
      @team_plans = team_plans_group.plans
    else
      @team_plans = Plan.where("id < 0")
    end

    # We need to load all plans in case a user is on a plan that is deprecated
    @all_plans = Plan.where("id > 0")
  end
end
