class ShoverJob < Job
  attr_accessor :user_id, :event, :data, :timestamp

  def initialize(user_id, event, data, timestamp)
    self.user_id = user_id
    self.event = event
    self.data = data
    self.timestamp = timestamp
  end

  def perform
    if user_id.present?
      Shover.post_publish user_id, event, data, timestamp
    else
      Shover.post_broadcast event, data, timestamp
    end
  end

  def self.submit_job(user_id, event, data, timestamp)
    Delayed::Job.enqueue(self.new(user_id, event, data, timestamp))
  end
end
