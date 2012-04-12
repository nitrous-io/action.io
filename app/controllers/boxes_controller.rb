class BoxesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_box, only: [:show, :update, :destroy]
  respond_to :json

  def index
    @boxes = current_user.boxes
    respond_with @boxes
  end

  def create
    @box = Box.new params.slice(:name, :region)
    @box.owner = current_user
    @box.box_template = BoxTemplate.find(params[:box_template_id]) if params[:box_template_id]
    @box.save
    respond_with @box
  end

  def show
    respond_with @box
  end

  def update
    @box.update_attributes params.slice(:name, :region)
    respond_with @box
  end

  def destroy
    @box.destroy
    respond_with @box
  end

  private
  def find_box
    @box = current_user.boxes.find(params[:id])
  end
end
