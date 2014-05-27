class BoxhostsController < ApplicationController
  protect_from_forgery

  before_filter :authenticate_user!
  before_filter :check_if_delinquent_user!
  before_filter :allow_only_dedicated_users

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
    if boxhost_params[:location_id]
      @boxhost.location = Location.where(id: boxhost_params[:location_id]).first
    end
    @boxhost.save

    respond_with @boxhost
  end

  def provision
    @boxhost.enqueue_provision!
    TrackMixpanelEventJob.submit_job('Boxhost provisioned', current_user.id)
    respond_with @boxhost
  end

  private
  def find_own_boxhost
    @boxhost = current_user.visible_boxhosts.find(params[:id])
  end
end
