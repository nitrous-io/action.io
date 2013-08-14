class DeleteMixpanelUserJob < Job
  attr_accessor :email

  def initialize(email)
    self.email = email
  end

  def perform
    mixpanel = Mixpanel::Tracker.new ENV['MIXPANEL_TOKEN']
    mixpanel.delete(email)
  end

  def self.submit_job(email)
    Delayed::Job.enqueue(self.new(email))
  end
end
