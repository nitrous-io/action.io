class AddonsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :json

  def index
    @addons = Addon.enabled
    respond_with @addons
  end
end
