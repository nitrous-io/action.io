class AddonsController < ApplicationController
  layout 'guest'
  respond_to :json, :html

  def index
    @addons = Addon.enabled.includes(:addon_category)
    respond_with @addons
  end

  def show
    @addon = Addon.enabled.find_by_uid params[:id]
    raise ActiveRecord::RecordNotFound unless @addon
    respond_with @addon
  end
end
