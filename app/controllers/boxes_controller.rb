class BoxesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_box, except: [:index, :create]
  respond_to :json

  def index
    @boxes = current_user.boxes
    respond_with @boxes
  end

  def create
    if current_user.boxes.unterminated.count == 0
      box_attrs = params[:box] || {}
      @box = Box.new(name: box_attrs[:name])
      @box.owner = current_user
      @box.box_template = BoxTemplate.find_by_image('rails')
      @box.region = Region.where(id: box_attrs[:region_id].to_s, enabled: true).first if box_attrs[:region_id]
      @box.save

      respond_with @box
    else
      render status: 422, json: {
        errors: {
          base: ['You can only create one box during the private beta period.']
        }
      }
    end
  end

  def show
    respond_with @box
  end

  def update
    box_attrs = params[:box] || {}
    @box.name = box_attrs[:name]
    @box.region = Region.find(box_attrs[:region_id]) if box_attrs[:region_id]
    @box.save
    respond_with @box
  end

  def destroy
    @box.enqueue_terminate!
    respond_with @box
  end

  def start
    @box.enqueue_start!
    respond_with @box
  end

  def suspend
    @box.enqueue_suspend!
    respond_with @box
  end

  def resume
    @box.enqueue_resume!
    respond_with @box
  end

  def stop
    @box.enqueue_stop!
    respond_with @box
  end

  def terminal
    render layout: 'terminal'
  end

  private
  def find_box
    @box = current_user.boxes.find(params[:id])
  end
end
