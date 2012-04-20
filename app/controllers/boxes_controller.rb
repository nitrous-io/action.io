class BoxesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_box, except: [:index, :create]
  respond_to :json

  def index
    @boxes = current_user.boxes
    respond_with @boxes
  end

  def create
    @box = Box.new params.slice(:name)
    @box.owner = current_user
    @box.box_template = BoxTemplate.find(params[:box_template_id]) if params[:box_template_id]
    @box.region = Region.find(params[:region_id]) if params[:region_id]
    @box.save
    respond_with @box
  end

  def show
    respond_with @box
  end

  def update
    @box.name = params[:name]
    @box.region = Region.find(params[:region_id]) if params[:region_id]
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
    tty_keys_hash = Hash[current_user.boxes.select('boxes.id, boxes.key').map do |box|
      verifier = ActiveSupport::MessageVerifier.new(box.key, serializer: Serializers::JSONSerializer)
      [box.id.to_s, verifier.generate(current_user.id.to_s)]
    end]

    cookies[:_aio_tty_keys] = {
      value: Base64.encode64(tty_keys_hash.to_json),
      domain: '.' + Settings.domain,
      httponly: true
    }

    render layout: false
  end

  private
  def find_box
    @box = current_user.boxes.find(params[:id])
  end
end
