class Admin::RegionsController < AdminController
  before_filter :find_region, except: [:index]

  def index
    @regions = Region.order(:name)
  end

  def start_to_go_down
    send_event_to_region(:start_to_go_down!)
  end

  def go_up
    send_event_to_region(:go_up!)
  end

  def go_down
    send_event_to_region(:go_down!)
  end

  def disable_box_creation
    send_event_to_region(:disable_box_creation!)
  end

  def enable_box_creation
    send_event_to_region(:enable_box_creation!)
  end

  protected
  def send_event_to_region(event)
    @region.send(event)
    flash[:notice] = "Changed #{@region.name}'s state to #{@region.state}"
    redirect_to admin_regions_url
  end

  def find_region
    @region = Region.find(params[:id])
  end
end
