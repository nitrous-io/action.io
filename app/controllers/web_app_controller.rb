class WebAppController < ApplicationController
  before_filter :authenticate_user!
  layout 'basic'

  def index
    @boxes = current_user.visible_boxes
    @regions = Region.enabled
    @box_templates = BoxTemplate.all
  end
end
