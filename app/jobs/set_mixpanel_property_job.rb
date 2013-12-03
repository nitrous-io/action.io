class SetMixpanelPropertyJob < Job
  attr_accessor :user_id, :properties

  def initialize(user_id, property, value=nil)
    self.user_id = user_id

    # instead of a single property,
    # you can also pass a hash of properties
    if property.kind_of? Hash
      self.properties = property
    else
      self.properties = { property => value }
    end
  end

  def perform
    user = User.find(self.user_id)

    mixpanel = Mixpanel::Tracker.new ENV['MIXPANEL_TOKEN']
    mixpanel.set user.email, self.properties
  end

  def self.submit_job(user_id, property, value=nil)
    Delayed::Job.enqueue(self.new(user_id, property, value))
  end
end

