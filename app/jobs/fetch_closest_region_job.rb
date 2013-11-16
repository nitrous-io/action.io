class FetchClosestRegionJob < Job
  attr_accessor :ip
  attr_accessor :user_id

  def initialize(ip, user_id)
    self.ip = ip
    self.user_id = user_id
  end

  def perform
    location = Geocoder.search(ip)
    return if location.blank?

    region = Region.recommended_for(
      continent: location.continent_code,
      country: location.country_code,
      state: location.state_code
    )
    return if region.blank?

    channel = Pusher["private-user-#{user_id}"]
    channel.trigger 'aio:fetch_closest_region', region.to_json
  end
end
