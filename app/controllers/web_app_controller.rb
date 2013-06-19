class WebAppController < ApplicationController
  before_filter :authenticate_user!

  layout 'basic'

  def index
    # since we dont use default render :json here, manually create a active
    # model serializer instance here so we can access url helpers with
    # `url_options`
    @user_serializer = current_user.active_model_serializer.new current_user,
      scope: current_user, url_options: url_options
    @boxes = current_user.visible_boxes
    @regions = Region.enabled
    @box_templates = BoxTemplate.all
    @n2o_128mb_memory = KeyValue[N2oAllocation::N2O_128MB_MEMORY]
    @n2o_250mb_storage = KeyValue[N2oAllocation::N2O_250MB_STORAGE]
  end
end
