class BoxesController < ApplicationController
  before_filter :authenticate_user!, except: [:webhook]
  before_filter :authenticate_coach!, only: [:webhook]
  before_filter :find_box, except: [:index, :create, :webhook]
  respond_to :json

  BETA_LIMIT  = 3

  def index
    @boxes = current_user.functional_boxes
    respond_with @boxes
  end

  def create
    if current_user.boxes.unterminated.count < BETA_LIMIT
      box_attrs = params[:box] || {}
      @box = Box.new(name: box_attrs[:name])
      @box.owner = current_user
      @box.setup box_attrs
      respond_with @box
    else
      render status: 422, json: {
        errors: {
          base: ["You can only create #{BETA_LIMIT} #{'box'.pluralize(BETA_LIMIT)} during the private beta period."]
        }
      }
    end
  end

  def show
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

  def restart
    @box.enqueue_restart!
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
    render json: {status: 'ok'}, status: 200
  end

  def default_public_key
    Delayed::Job.enqueue(ReadDefaultPublicKeyJob.new(@box.id))
    render json: {status: 'ok'}, status: 200
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
