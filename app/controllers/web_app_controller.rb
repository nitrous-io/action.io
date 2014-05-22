class WebAppController < ApplicationController
  before_filter :authenticate_user!

  layout 'basic'

  def index
    @boxes = current_user.visible_boxes
    @snapshots = current_user.snapshots.undeleted
    @repositories = current_user.repositories
    @public_keys = current_user.public_keys
    @locations = Location.all
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

    @personal_plan_ids = Plan.for_plan_group(current_user.plan_group.try(:name) || PlanGroup::DEFAULT_NAME).select(&:id).map(&:id) || []
    @team_plan_ids = current_user.team_plans_enabled? ? Plan.for_plan_group(PlanGroup::TEAM_NAME).select(&:id).map(&:id) : []
    visible_plan_ids = (@personal_plan_ids + @team_plan_ids + [current_user.subscription.try(:plan_id)]).compact.uniq
    @plans = Plan.where('id IN (?)', visible_plan_ids)

    if current_user.dedicated_allowed
      @boxhost_plans = BoxhostPlan.all
    end
  end
end
