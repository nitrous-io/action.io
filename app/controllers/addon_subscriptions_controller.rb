class AddonSubscriptionsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :json

  def index
    @box = current_user.owned_boxes.find params[:box_id]
    @addon_subscriptions = @box.addon_subscriptions
    respond_with @addon_subscriptions
  end

  def create
    @box = current_user.owned_boxes.find params[:addon_subscription][:box_id]
    @addon = Addon.find params[:addon_subscription][:addon_id]
    @subscription = AddonSubscription.provision @addon, @box
    respond_with @subscription
  end

  def show
    respond_with current_subscription
  end

  def destroy
    DeprovisionAddonJob.new(current_subscription.id).delay.perform
    respond_with current_subscription
  end

  protected
  def current_subscription
    @subscription ||= AddonSubscription.find params[:id]
    unless current_user.owned_boxes.where(id: @subscription.box_id).exists?
      raise ActiveRecord::RecordNotFound
    end
    @subscription
  end
end
