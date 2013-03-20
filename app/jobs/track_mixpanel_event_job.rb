class TrackMixpanelEventJob < Job
  attr_accessor :event, :user_id, :properties

  def initialize(event, user_id = nil, properties={})
    self.event = event
    self.user_id = user_id
    self.properties = properties || {}
  end

  def perform
    if self.user_id.present?
      user = User.find(self.user_id)
      self.properties.merge!(email: user.email, distinct_id: user.email)
    end

    mixpanel = Mixpanel::Tracker.new ENV['MIXPANEL_TOKEN']
    mixpanel.track event, properties
  end

  def self.submit_job(event, user_id = nil, properties = {})
    Delayed::Job.enqueue(self.new(event, user_id, properties))
  end
end


