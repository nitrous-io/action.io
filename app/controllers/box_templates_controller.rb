class BoxTemplatesController < ApplicationController
  before_filter :authenticate_user!
  respond_to :json

  def index
    @box_templates = current_user.admin? ? BoxTemplate.all : BoxTemplate.available_to_regular_users.all
    respond_with @box_templates
  end

  def show
    @box_template = BoxTemplate.find(params[:id])
    respond_with @box_template
  end
end
