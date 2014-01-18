class Admin::BoxesController < AdminController
  layout 'dashboard'
  respond_to :html

  before_filter :find_box, except: [:index]

  def index
    if id = params[:id].to_i
      @box = Box.find_by id: id
    end
  end

  def retry_start
    if @box.state == 'starting'
      @box.update_attribute 'state', 'stopped'
      @box.enqueue_start!
      flash[:notice] = "Retrying start for #{@box.name}"
    end

    redirect_to admin_boxes_path(id: @box.to_param)
  end

  def retry_stop
    if @box.state == 'stopping'
      @box.update_attribute 'state', 'running'
      @box.enqueue_stop!
      flash[:notice] = "Retrying stop for #{@box.name}"
    end

    redirect_to admin_boxes_path(id: @box.to_param)
  end

  def retry_restart
    if @box.state == 'restarting'
      @box.update_attribute 'state', 'running'
      @box.enqueue_restart!
      flash[:notice] = "Retrying restart for #{@box.name}"
    end

    redirect_to admin_boxes_path(id: @box.to_param)
  end

  def force_terminate
    if @box.state == 'terminating'
      @box.terminate!
      flash[:notice] = "Terminated box #{@box.name}"
    else
      flash[:notice] = "Box (#{@box.name}) is already terminated"
    end

    redirect_to admin_boxes_path(id: @box.to_param)
  end

  private
  def find_box
    @box = Box.find params[:id]
  end
end
