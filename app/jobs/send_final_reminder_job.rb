class SendFinalReminderJob < Job
  attr_accessor :user_id, :discount

  def initialize(user_id, discount)
    self.user_id = user_id
    self.discount = discount
  end

  def perform
    UserMailer.final_reminder(user_id, discount).deliver
    TrackMixpanelEventJob.submit_job('Final Reminder Sent', user_id, discount: discount)
  end

  def self.submit_job(user_id, discount)
    Delayed::Job.enqueue(new(user_id, discount))
  end
end
