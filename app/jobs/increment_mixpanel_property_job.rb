class IncrementMixpanelPropertyJob
  attr_accessor :user_id, :property, :value

  def initialize(user_id, property, value)
    self.user_id = user_id
    self.property = property
    self.value = value
  end

  def perform
    user = User.find(self.user_id)

    mixpanel = Mixpanel::Tracker.new ENV['MIXPANEL_TOKEN']
    mixpanel.increment user.email, { self.property => self.value }
  end

  def self.submit_job(user_id, property, value)
    Delayed::Job.enqueue(self.new(user_id, property, value))
  end
end
