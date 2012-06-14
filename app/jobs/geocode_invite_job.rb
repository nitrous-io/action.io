class GeocodeInviteJob
  attr_accessor :invite_id

  def initialize(invite_id)
    self.invite_id = invite_id
  end

  def perform
    invite = Invite.find(self.invite_id)
    return if invite.ip.blank?

    geocoded_result = Geocoder.search(invite.ip).first
    unless geocoded_result.blank?
      invite.city = geocoded_result.data['city']
      invite.country = geocoded_result.data['country_name']
      invite.country_code = geocoded_result.data['country_code']
      invite.latitude = geocoded_result.data['latitude'].to_f
      invite.longitude = geocoded_result.data['longitude'].to_f

      invite.save!
    end
  end
end