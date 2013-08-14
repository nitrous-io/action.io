class AddonsController < ApplicationController
  layout 'guest'
  respond_to :json, :html

  def index
    @addons = Addon.enabled.includes(:addon_category)
    respond_with @addons
  end
end
