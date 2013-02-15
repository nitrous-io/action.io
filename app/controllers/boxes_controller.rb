class BoxesController < ApplicationController
  before_filter :authenticate_user!, except: [:webhook, :touch]
  before_filter :authenticate_coach!, only: [:webhook]
  before_filter :find_box, except: [:index, :create, :webhook, :touch]
  respond_to :json

  def index
    @boxes = current_user.functional_boxes
    respond_with @boxes
  end

  def create
    @box = current_user.create_box(params[:box] || {})
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
    TrackMixpanelEventJob.submit_job('Box Stopped', current_user.id)
    IncrementMixpanelPropertyJob.submit_job(current_user.id, :boxes_running, -1)
    respond_with @box
  end

  def restart
    @box.enqueue_restart!
    TrackMixpanelEventJob.submit_job('Box Restarted', current_user.id)
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
    when 'aio:snapshotted'
      snapshot = @box.snapshots.find parsed_message['returnVars']['snapshot_id']
      snapshot.finish parsed_message['snapshotUrl']
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

  def authenticate_coach!
    authenticate_or_request_with_http_basic do |username, password|
      username == ENV['WEBHOOK_USERNAME'] && password == ENV['WEBHOOK_PASSWORD']
    end
  end
end
