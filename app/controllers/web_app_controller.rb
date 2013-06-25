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
  end
end
