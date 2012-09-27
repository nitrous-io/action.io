class RegionsController < ApplicationController
  respond_to :json

  def index
    @regions = Region.enabled.all
    respond_with @regions
  end
end

