class BoxesController < ApplicationController
  protect_from_forgery except: [:touch, :track_preview, :webhook]

  rescue_from StateMachine::InvalidTransition, with: :rescue_invalid_box_transition

  before_filter :authenticate_user!, except: [:webhook, :touch, :track_preview]
  before_filter :authenticate_coach!, only: [:webhook]

  before_filter :check_if_delinquent_user!, except: [ :index, :destroy, :webhook, :touch, :track_preview ]
  before_filter :find_box, only: [:terminal, :show, :add_public_key_to_github, :default_public_key]
  before_filter :find_own_box, only: [:destroy, :start, :stop, :update, :restart, :provision, :auth, :custom_domain, :clone_repo, :info]
  before_filter :check_backend_availability, only: [:start, :stop, :update, :destroy, :update,
                                                    :restart, :provision, :terminal, :info, :clone_repo,
                                                    :add_public_key_to_github, :default_public_key]

  respond_to :json

  def index
    @boxes = current_user.visible_boxes
    respond_with @boxes
  end

  def create
    box_params = params[:box]
    user = self.current_user

    if region_name = box_params.delete(:region)
      box_params[:region_id] ||= Region.select('regions.id').
        joins(:boxhosts).
        where(name: region_name, enabled: true).
        where('boxhosts.type = ?', 'FreeBoxhost').
        first.try(:id)
    end

    if box_template_name = box_params.delete(:box_template)
      box_params[:box_template_id] ||= BoxTemplate.select(:id).where(runtime: box_template_name.to_s).first.try(:id)
    end

    @box = Box.new(
      name:    box_params[:name],
      memory:  box_params[:memory] || KeyValue[Box::N2O_MIN_MEMORY_MB],
      storage: box_params[:storage] || KeyValue[Box::N2O_MIN_STORAGE_MB]
    )

    # Setting a source snapshot takes priority over box template.
    if box_params[:source_snapshot_id].present?
      @box.source_snapshot = Snapshot.find(box_params[:source_snapshot_id])
    else
      if box_params[:box_template_id]
        box_template = BoxTemplate.where(id: box_params[:box_template_id], enabled: true).first
        @box.box_template = (box_template.try(:admin?) && !user.admin?) ? nil : box_template
      end
    end

    if region_id = box_params.delete(:region_id)
      @box.boxhost = FreeBoxhost.
        joins(:region).
        where('regions.id' => region_id, 'regions.enabled' => true).first
    end

    @box.owner = user
    if (plan = user.active_plan)
      @box.cpu_multiplier = plan.cpu_multiplier || 1
      @box.virtual_memory = plan.vmem_multiplier * @box.memory
    end

    clone_url = nil
    if repo_params = box_params[:repository]
      if repo_params[:state] == 'identified'
        clone_url = repo_params[:clone_url]
        repo = @box.repositories.build(clone_url: clone_url)
        repo.scm = repo_params[:scm]
        repo.state = repo_params[:state]
        repo.file_to_open = repo_params[:file_to_open]
        repo.download_branch = repo_params[:download_branch]
      end
    end

    User.with_advisory_lock("user-n2o-#{current_user.id}") do
      if @box.save
        @box.transition_triggered(:enqueue_provision!, 'system')
        IncrementMixpanelPropertyJob.submit_job(user.id, :boxes_created, 1)
        if user.owned_boxes.count == 1 && @box.box_template
          SetMixpanelPropertyJob.submit_job(user.id, :initial_box_template, @box.box_template.name)
        end

        mixpanel_properties = {
          memory: @box.memory,
          storage: @box.storage,
          region: @box.region.name,
        }
        mixpanel_properties[:snapshot] = @box.source_snapshot.id if @box.source_snapshot
        mixpanel_properties[:template] = @box.box_template.name if @box.box_template
        if clone_url.present?
          mixpanel_properties[:cloned_repo] = clone_url
          IncrementMixpanelPropertyJob.submit_job(user.id, :repos_cloned, 1)
        end

        TrackMixpanelEventJob.submit_job('Box Created', user.id, mixpanel_properties)
      end
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

    User.with_advisory_lock("user-n2o-#{current_user.id}") do
      if @box.configuration_changed? && @box.save
        @box.transition_triggered(:enqueue_reconfigure!, user)

        mixpanel_event = allocation_needed ? 'Upgraded' : 'Downgraded'

        TrackMixpanelEventJob.submit_job("Box Configuration #{mixpanel_event}", current_user.id)
      end
    end

    respond_with @box
  end

  def auth
    @box.update_auth params[:box][:auth_username], params[:box][:auth_password]
    respond_with @box
  end

  def custom_domain
    @box.update_custom_domain params[:box][:custom_domain]
    respond_with @box
  end

  def clone_repo
    repo_params = params[:repository]

    if repo_params && repo_params[:state] == 'identified' && (@box.running? || @box.stopped?)
      repo              = @box.repositories.build
      repo.clone_url    = repo_params[:clone_url]
      repo.scm          = repo_params[:scm]
      repo.state        = repo_params[:state]
      repo.file_to_open = repo_params[:file_to_open]
      repo.download_branch = repo_params[:download_branch]

      repo.save

      if @box.running?
        @box.transition_triggered('enqueue_clone_repo!', current_user)
        repo.initiate_clone!
      else
        # After the box has been started, cloning will commence
        # Goboxer requires that the box is started first before
        # cloning begins
        @box.enqueue_start!
      end

      TrackMixpanelEventJob.submit_job('Repo Cloned', current_user.id, box: @box.id, clone_url: repo.clone_url)
      IncrementMixpanelPropertyJob.submit_job(current_user.id, :repos_cloned, 1)
    else
      @box.errors.add(:base, 'no repository created')
    end

    respond_with @box
  end

  def destroy
    @box.transition_triggered(:enqueue_terminate!, current_user)
    TrackMixpanelEventJob.submit_job('Box Terminated', current_user.id)
    IncrementMixpanelPropertyJob.submit_job(current_user.id, :boxes_terminated, 1)
    respond_with @box
  end

  def start
    @box.transition_triggered(:enqueue_start!, current_user)
    TrackMixpanelEventJob.submit_job('Box Started', current_user.id)
    IncrementMixpanelPropertyJob.submit_job(current_user.id, :boxes_running, 1)
    respond_with @box
  end

  def stop
    @box.transition_triggered(:enqueue_stop!, current_user)
    TrackMixpanelEventJob.submit_job('Box Stopped', current_user.id)
    IncrementMixpanelPropertyJob.submit_job(current_user.id, :boxes_running, -1)
    respond_with @box
  end

  def restart
    @box.transition_triggered(:enqueue_restart!, current_user)
    TrackMixpanelEventJob.submit_job('Box Restarted', current_user.id)
    respond_with @box
  end

  def provision
    @box.transition_triggered(:enqueue_provision!, current_user)
    TrackMixpanelEventJob.submit_job('Box Provisioning Retried', current_user.id)
    respond_with @box
  end

  def terminal
    render layout: 'terminal'
  end

  def webhook
    @box = Box.find(params[:id])
    parsed_message = JSON.parse(params[:payload])
    def box_event(event)
      @box.transition_triggered(event, 'webhook')
    end

    case parsed_message['type']
    when 'aio:created'
      if parsed_message['success']
        @box.host = parsed_message['id']
        @box.port = parsed_message['port']

        box_event(:enqueue_start!)
      else
        box_event(:orphan!)
      end
    when 'aio:started'
      unless @box.running?
        if (data = parsed_message['data'])
          @box.memory = data['memory']
          @box.virtual_memory = data['virtualMemory']
          @box.cpu_shares = data['cpuShares']
        end

        if (repo = @box.last_added_repository) && repo.identified?
          repo.initiate_clone!
          box_event(:enqueue_clone_repo!)
        else
          box_event(:start!)
        end
      end
    when 'aio:stopped'
      unless @box.stopped?
        box_event(:stop!)
      end
    when 'aio:restarted'
      unless @box.running?
        if (data = parsed_message['data'])
          @box.memory = data['memory']
          @box.virtual_memory = data['virtualMemory']
          @box.cpu_shares = data['cpuShares']
        end
        box_event(:restart!)
      end
    when 'aio:destroyed'
      unless @box.terminated?
        if @box.owner.present?
          box_event(:terminate!)
        else
          @box.update_attribute :state, 'terminated'
        end
      end
    when 'aio:snapshotted'
      unless @box.stopped?
        if parsed_message['success']
          @box.complete_snapshot(
            parsed_message['snapshotId'],
            url: parsed_message['snapshotUrl'],
            size: parsed_message['snapshotSize']
          )
        else
          @box.fail_snapshot(parsed_message['snapshotId'])
        end
      end
    when 'aio:cloned_repository'
      if (repo = @box.repository_being_cloned)
        mixpanel_properties = {
          box: @box.id,
          clone_url: repo.clone_url,
        }
        if parsed_message['success']
          repo.cloned!
          TrackMixpanelEventJob.submit_job('Repo Cloning Succeeded', repo.user.id, mixpanel_properties)
        else
          repo.failure_reason = parsed_message['error']
          repo.failed!
          TrackMixpanelEventJob.submit_job('Repo Cloning Failed', repo.user.id, mixpanel_properties)
        end

        box_event(:complete_clone_repo!)
      end
    when 'aio:configured'
      data_type = parsed_message['dataType']
      data = parsed_message['data']
      if data_type == 'aio:configured:change_specs'
        @box.memory = data['memory']
        @box.storage = data['diskSpace']
        @box.virtual_memory = data['virtualMemory']
        @box.cpu_shares = data['cpuShares']
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

    if params[:event].nil? || (params[:event] == 'heartbeat' && (box.last_heartbeat_tracked_at.nil? || (box.last_heartbeat_tracked_at + 30.minutes < now)))
      TrackMixpanelEventJob.submit_job 'Box Heartbeat', owner.id
      box.last_heartbeat_tracked_at = now
    end

    box.touched_at = now
    box.save!

    render json: { status: 'ok' }, status: 200
  end

  def track_preview
    box = Box.find(params[:id].to_s)
    owner = box.owner

    TrackMixpanelEventJob.submit_job 'Preview URL Visited', owner.id

    render json: { status: 'ok'}, status: 200
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

  def rescue_invalid_box_transition(exception)
    Airbrake.notify_or_ignore(exception) if defined? Airbrake
    render json: { status: 'Invalid box transition' }, status: :conflict
  end
end
