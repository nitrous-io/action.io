class BoxesController < ApplicationController
  protect_from_forgery except: [:touch]

  before_filter :authenticate_user!, except: [:webhook, :touch]
  before_filter :authenticate_coach!, only: [:webhook]

  before_filter :find_box, only: [:terminal, :show, :add_public_key_to_github, :default_public_key, :info]
  before_filter :find_own_box, only: [:destroy, :start, :stop, :update, :restart, :provision, :auth]
  before_filter :check_backend_availability, only: [:start, :stop, :update, :destroy, :update,
                                                    :restart, :provision, :terminal,
                                                    :add_public_key_to_github, :default_public_key, :info]

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

    @box = Box.new(
      name:    box_params[:name],
      memory:  box_params[:memory] || 384,
      storage: box_params[:storage] || 750
    )

    if box_params[:box_template_id]
      box_template = BoxTemplate.where(id: box_params[:box_template_id], enabled: true).first
      @box.box_template = (box_template.try(:admin?) && !current_user.admin?) ? nil : box_template
    end

    if box_params[:region_id]
      @box.region = Region.where(id: box_params[:region_id].to_s, enabled: true).first
    end

    user = self.current_user

    @box.owner = user
    if (plan = user.active_plan)
      @box.cpu_multiplier = plan.cpu_multiplier || 1
      @box.virtual_memory = plan.vmem_multiplier * @box.memory
    end

    if @box.save
      @box.enqueue_provision!
      IncrementMixpanelPropertyJob.submit_job(user.id, :boxes_created, 1)
      TrackMixpanelEventJob.submit_job( 'Box Created', user.id, { memory: @box.memory, storage: @box.storage, template: @box.box_template.name, region: @box.region.name })
    end

    respond_with @box
  end

  def show
    respond_with @box
  end

  def update
    box_params = params[:box]

    @box.memory = box_params[:memory]
    @box.storage = box_params[:storage]

    user = self.current_user
    if (plan = user.active_plan)
      @box.virtual_memory = plan.vmem_multiplier * @box.memory
    end

    allocation_needed = @box.n2o_allocation_needed?

    if @box.configuration_changed? && @box.save
      @box.enqueue_reconfigure!

      mixpanel_event = allocation_needed ? 'Upgraded' : 'Downgraded'

      TrackMixpanelEventJob.submit_job("Box Configuration #{mixpanel_event}", current_user.id)
    end

    respond_with @box
  end

  def auth
    @box.update_auth params[:box][:auth_username], params[:box][:auth_password]
    respond_with @box
  end

  def destroy
    @box.enqueue_terminate!
    TrackMixpanelEventJob.submit_job('Box Terminated', current_user.id)
    IncrementMixpanelPropertyJob.submit_job(current_user.id, :boxes_terminated, 1)
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
      if (data = parsed_message['data'])
        @box.memory = data['memory']
        @box.virtual_memory = data['virtualMemory']
        @box.cpu_shares = data['cpuShares']
      end
      @box.start!
    when 'aio:stopped'
      @box.stop!
    when 'aio:restarted'
      if (data = parsed_message['data'])
        @box.memory = data['memory']
        @box.virtual_memory = data['virtualMemory']
        @box.cpu_shares = data['cpuShares']
      end
      @box.restart!
    when 'aio:destroyed'
      if @box.owner.present?
        @box.terminate!
      else
        @box.update_attribute :state, 'terminated'
      end
    when 'aio:configured'
      data_type = parsed_message['dataType']
      data = parsed_message['data']
      if data_type == 'aio:configured:change_specs'
        @box.memory = data['memory']
        @box.storage = data['diskSpace']
        @box.virtual_memory = data['virtualMemory']
        @box.cpu_shares = data['cpuShares']
        @box.reconfigure!
      end
    when 'aio:info_response'
      websocket_payload = {
        box: {
          id: @box.id,
          memory_usage: parsed_message['info']['memoryUsage'],
          storage_usage: parsed_message['info']['storageUsage'],
          lxc_status: parsed_message['info']['lxcStatus']
        }
      }
      Shover.publish @box.owner_id, 'aio:box_info_response', websocket_payload
      Pusher["private-user-#{@box.owner_id}"].trigger 'aio:box_info_response', websocket_payload.to_json
    when 'aio:migrated'
      if parsed_message['success']
        @box.finish_migration
      end
    end
    render json: {status: 'ok'}, status: 200
  end

  def add_public_key_to_github
    Delayed::Job.enqueue(SetupGithubKeyJob.new(@box.id))
    IncrementMixpanelPropertyJob.submit_job(current_user.id, :public_keys_added_to_github, 1)
    TrackMixpanelEventJob.submit_job('Github Added Key', current_user.id)

    render json: { status: 'ok' }, status: :ok
  end

  def info
    Delayed::Job.enqueue(FetchBoxInfoJob.new(@box.id, current_user.id))
    render json: { status: 'ok' }, status: :ok
  end

  def default_public_key
    Delayed::Job.enqueue(ReadDefaultPublicKeyJob.new(@box.id, current_user.id))
    render json: { status: 'ok' }, status: :ok
  end

  def touch
    now = Time.now
    box = Box.find(params[:id].to_s)

    owner = box.owner

    if params[:event].nil?
      TrackMixpanelEventJob.submit_job 'SSH Session Started', owner.id
      IncrementMixpanelPropertyJob.submit_job(owner.id, :ssh_sessions_started, 1)
    end

    if params[:event].nil? || (params[:event] == 'heartbeat' && (box.last_heartbeat_tracked_at.nil? || (box.last_heartbeat_tracked_at + 15.minutes < now)))
      TrackMixpanelEventJob.submit_job 'Box Heartbeat', owner.id
      box.last_heartbeat_tracked_at = now
    end

    box.touched_at = now
    box.save!

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
    unless (current_user.admin? || @box.backend_available?)
      render json: { errors: { base: ["The Nitrous.IO backend is temporarily unavailable. Please try again later or contact us at support@nitrous.io."] } }, status: :unprocessable_entity
    end
  end

  def authenticate_coach!
    authenticate_or_request_with_http_basic do |username, password|
      username == ENV['WEBHOOK_USERNAME'] && password == ENV['WEBHOOK_PASSWORD']
    end
  end
end
