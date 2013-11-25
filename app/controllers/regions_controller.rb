class RegionsController < ApplicationController
  before_filter :authenticate_user!, only: [:fetch_closest]
  respond_to :json

  def index
    @regions = Region.enabled.all
    respond_with @regions
  end

  def closest
    ip = request.remote_ip
    render json: { error: 'invalid ip' }, status: :not_found and return if ip.blank?

    location = Geocoder.search(ip)
    if location
      @region = Region.recommended_for(
        continent: location.continent_code,
        country: location.country_code,
        state: location.state_code
      )
    end

    if @region
      respond_with @region
    else
      render json: { error: 'unknown closest region' }, status: :not_found
    end
  end

  def fetch_closest
    ip = request.remote_ip
    render json: { error: 'invalid ip' }, status: :not_found and return if ip.blank?

    Delayed::Job.enqueue(FetchClosestRegionJob.new(ip, current_user.id))
    render json: { status: 'ok' }, status: :ok
  end
end
