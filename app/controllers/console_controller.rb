class ConsoleController < ApplicationController
  before_filter :authenticate_user!

  def index
    @boxes = current_user.boxes
    @box_templates = BoxTemplate.all
  end
end

