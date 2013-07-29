class AddonsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :json

  def index
    @addons = Addon.all
    respond_with @addons
  end
end
