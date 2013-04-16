class BoxesController < ApplicationController
  before_filter :authenticate_user!, except: [:webhook, :touch]
  before_filter :authenticate_coach!, only: [:webhook]
  before_filter :find_box, only: [:terminal, :show, :add_public_key_to_github, :default_public_key]
  before_filter :find_own_box, only: [:destroy, :start, :stop, :restart, :provision]

  before_filter :check_backend_availability, except: [:index, :create, :show, :webhook, :touch]

  respond_to :json

  def index
    @boxes = current_user.visible_boxes
    respond_with @boxes
  end

  def create
    box_params = params[:box]
    if region_name = box_params.delete(:region)
      box_params[:region_id] ||= Region.select(:id).where(name: region_name.to_s).first.try(:id)
    end
    if box_template_name = box_params.delete(:box_template)
      box_params[:box_template_id] ||= BoxTemplate.select(:id).where(runtime: box_template_name.to_s).first.try(:id)
    end
    @box = current_user.create_box(box_params || {})
    respond_with @box
  end

  def show
    respond_with @box
  end

  def destroy
    @box.enqueue_terminate!
    TrackMixpanelEventJob.submit_job('Box Terminated', current_user.id)
    IncrementMixpanelPropertyJob.submit_job(current_user.id, :boxes_created, -1)
    respond_with @box
  end

  def start
    @box.enqueue_start!
    TrackMixpanelEventJob.submit_job('Box Started', current_user.id)
    IncrementMixpanelPropertyJob.submit_job(current_user.id, :boxes_running, 1)
    respond_with @box
  end

  def stop
    @box.enqueue_stop!
    TrackMixpanelEventJob.submit_job('Box Stopped', current_user.id)
    IncrementMixpanelPropertyJob.submit_job(current_user.id, :boxes_running, -1)
    respond_with @box
  end

  def restart
    @box.enqueue_restart!
    TrackMixpanelEventJob.submit_job('Box Restarted', current_user.id)
    respond_with @box
  end

  def provision
    @box.enqueue_provision!
    TrackMixpanelEventJob.submit_job('Box Provisioning Retried', current_user.id)
    respond_with @box
  end

  def terminal
    render layout: 'terminal'
  end

  def webhook
    @box = Box.find(params[:id])
    parsed_message = JSON.parse(params[:payload])

    case parsed_message['type']
    when 'aio:created'
      if parsed_message['success']
        @box.host = parsed_message['id']
        @box.port = parsed_message['port']
        @box.save
        @box.enqueue_start!
      else
        @box.orphan!
      end
    when 'aio:started'
      @box.start!
    when 'aio:stopped'
      @box.stop!
    when 'aio:restarted'
      @box.restart!
    when 'aio:destroyed'
      @box.terminate!
    end

    render json: {status: 'ok'}, status: 200
  end

  def add_public_key_to_github
    Delayed::Job.enqueue(SetupGithubKeyJob.new(@box.id))
    IncrementMixpanelPropertyJob.submit_job(current_user.id, :public_keys_added_to_github, 1)
    TrackMixpanelEventJob.submit_job('Github Added Key', current_user.id)

    render json: {status: 'ok'}, status: 200
  end

  def default_public_key
    Delayed::Job.enqueue(ReadDefaultPublicKeyJob.new(@box.id))
    render json: {status: 'ok'}, status: 200
  end

  def touch
    box = Box.find(params[:id].to_s)
    box.update_attribute(:touched_at, Time.now)
    TrackMixpanelEventJob.submit_job 'SSH Session Started', box.owner.id
    render json: { status: 'ok' }, status: 200
  end

  protected
  def find_box
    @box = current_user.boxes.find(params[:id])
  end

  def find_own_box
    @box = current_user.owned_boxes.find(params[:id])
  end

  def check_backend_availability
    if !current_user.admin? && @box.backend_not_available?
      render json: { errors: { base: ["The Nitrous.IO backend is temporarily unavailable. Please try again later or contact us at support@nitrous.io."] } }, status: :unprocessable_entity
    end
  end

  def authenticate_coach!
    authenticate_or_request_with_http_basic do |username, password|
      username == ENV['WEBHOOK_USERNAME'] && password == ENV['WEBHOOK_PASSWORD']
    end
  end
end
