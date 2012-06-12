class ProjectsController < ApplicationController
  before_filter :authenticate_user!
  layout 'basic'

  def index
    @box_templates = BoxTemplate.all
    @regions = Region.order(:id).all
  end
end
