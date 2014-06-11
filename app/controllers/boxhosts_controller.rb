class BoxhostsController < ApplicationController
  protect_from_forgery except: [:webhook_provisioned]

  before_filter :authenticate_user!, except: [:webhook_provisioned]
  before_filter :authenticate_webhook_requests!, only: [:webhook_provisioned]

  before_filter :check_if_delinquent_user!, except: [:webhook_provisioned]
  before_filter :allow_only_dedicated_users, except: [:webhook_provisioned]

  before_filter :find_own_boxhost, only: [:show, :update, :provision]

  respond_to :json

  def index
    @boxhosts = current_user.visible_boxhosts
    respond_with @boxhosts
  end

  def show
    respond_with @boxhost
  end

  def update
    boxhost_params = params[:boxhost]

    @boxhost.name = boxhost_params[:name]
    if boxhost_params[:region_id]
      @boxhost.region = Region.where(id: boxhost_params[:region_id]).first
    end
    @boxhost.save

    respond_with @boxhost
  end

  def provision
    @boxhost.provision_webhook = webhook_provisioned_boxhost_url(
      @boxhost,
      user: ENV['BOXHOST_WEBHOOK_USERNAME'],
      password: ENV['BOXHOST_WEBHOOK_PASSWORD'],
    )
    @boxhost.enqueue_provision!
    TrackMixpanelEventJob.submit_job('Boxhost provisioned', current_user.id)
    respond_with @boxhost
  end

  def webhook_provisioned
    @boxhost = DedicatedBoxhost.find(params[:id])
    payload = JSON.parse(params[:payload])
    success = payload['success']

    if payload['message'].present?
      message = JSON.parse(payload['message'])
      @boxhost.host_identifier = message['id']
      @boxhost.ip = message['ip_address']
    end

    if success
      if @boxhost.host_identifier.blank? || @boxhost.ip.blank?
        render nothing: true, status: :unprocessable_entity
        return
      end

      @boxhost.start!
    else
      @boxhost.orphan!
    end

    render json: { status: 'ok' }, status: 200
  end

  private
  def find_own_boxhost
    @boxhost = current_user.visible_boxhosts.find(params[:id])
  end

  def authenticate_webhook_requests!
    authenticate_or_request_with_http_basic do |username, password|
      username == ENV['BOXHOST_WEBHOOK_USERNAME'] && password == ENV['BOXHOST_WEBHOOK_PASSWORD']
    end
  end
end
