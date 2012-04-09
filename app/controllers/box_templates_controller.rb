class BoxTemplatesController < ApplicationController
  respond_to :json

  def index
    @box_templates = BoxTemplate.all
    respond_with @box_templates
  end

  def show
    @box_template = BoxTemplate.find(params[:id])
    respond_with @box_template
  end
end
