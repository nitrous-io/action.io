class FreighterController < ApplicationController
  protect_from_forgery except: [:webhook]
  before_filter :authenticate_freighter!, only: [:webhook]

  class FreighterCallbackError < StandardError; end

  rescue_from FreighterCallbackError, with: :rescue_error
  rescue_from StateMachine::InvalidTransition, with: :rescue_error

  def webhook
    state = state_params
    @box = Box.find(state[:box_id])

    case params[:result] || state[:op] # result is not present on errors
    when 'created', 'provision'
      created_box
    when 'started', 'start'
      started_box
    when 'stopped', 'stop'
      stopped_box
    when 'restarted', 'restart'
      restarted_box
    when 'terminated', 'terminate'
      terminated_box
    end
    render nothing: true, status: :ok
  end

  protected

  def created_box # aio:created
    if params[:error]
      box_event(:orphan!)
      raise FreighterCallbackError.new(params[:error])
    end

    @box.container_uid = params[:container][:id]
    @box.port = params[:container][:ssh_port]

    # TODO: Freighter-provisioned boxes start immediately
    # We keep the enqueue here for now to preserve the existing state machine;
    # it's an extra step
    box_event(:enqueue_start!)
  end

  def started_box # aio:started
    raise FreighterCallbackError.new(params[:error]) if params[:error]
    return if @box.running?

    # TODO clone repo handling

    box_event(:start!)
  end

  def stopped_box # aio:stopped
    raise FreighterCallbackError.new(params[:error]) if params[:error]
    return if @box.stopped?

    box_event(:stop!)
  end

  def restarted_box # aio:restarted
    raise FreighterCallbackError.new(params[:error]) if params[:error]
    return if @box.running?

    box_event(:restart!)
  end

  def terminated_box # aio:destroyed
    raise FreighterCallbackError.new(params[:error]) if params[:error]
    return if @box.terminated?

    if @box.owner.present?
      box_event(:terminate!)
    else
      @box.update_attribute :state, 'terminated'
    end
  end

  def state_params
    Freighter.state_string_to_params params[:state]
  end

  def authenticate_freighter!
    # FIXME actual auth
    authorize_user! if Rails.env.production?
  end

  def rescue_error(exception)
    Airbrake.notify_or_ignore(exception) if defined? Airbrake
    render nothing: true, status: :conflict
  end

  def box_event(event)
    @box.transition_triggered(event, 'webhook')
  end
end
