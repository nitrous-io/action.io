class ConsoleController < ApplicationController
  before_filter :authenticate_user!
  layout 'console'

  def index
    @boxes = current_user.boxes
    @box_templates = BoxTemplate.all
    @regions = Settings.valid_regions
    @public_keys = current_user.public_keys
  end
end

