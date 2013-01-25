class TrackMixpanelEventJob
  attr_accessor :event, :user_id, :properties

  def initialize(event, user_id, properties={})
    self.event = event
    self.user_id = user_id
    self.properties = properties || {}
  end

  def perform
    user = User.find(self.user_id)

    mixpanel = Mixpanel::Tracker.new ENV['MIXPANEL_TOKEN']
    self.properties.merge!(email: user.email)

    mixpanel.track event, properties
  end

  def self.submit_job(event, user_id, properties = {})
    Delayed::Job.enqueue(self.new(event, user_id, properties))
  end
end


