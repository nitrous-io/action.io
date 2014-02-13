class WebAppController < ApplicationController
  before_filter :authenticate_user!

  layout 'basic'

  def index
    @boxes = current_user.visible_boxes
    @public_keys = current_user.public_keys
    @regions = Region.enabled
    @box_templates = BoxTemplate.all
    @n2o_128mb_memory = KeyValue[N2oAllocation::N2O_128MB_MEMORY]
    @n2o_250mb_storage = KeyValue[N2oAllocation::N2O_250MB_STORAGE]
    @bonus = current_user.bonus
    @bonus_info = Bonus.bonus_info
    @coupon_code = cookies.delete(:coupon_code)

    # Assuming that memory is divisible by 1024
    @max_memory_in_gb = KeyValue[Box::N2O_MAX_MEMORY_MB] / 1024
    # Assuming that storage is divisible by 1000
    @max_storage_in_gb = KeyValue[Box::N2O_MAX_STORAGE_MB] / 1000

    if (plan_group = current_user.plan_group).nil?
      @plans = Plan.global
    else
      @plans = plan_group.plans
    end

    @ember_alternatives = {}

    ember_split_alternatives.each do |view, template_alts|
      @ember_alternatives[view] = ab_test view, *template_alts
    end
  end
end
