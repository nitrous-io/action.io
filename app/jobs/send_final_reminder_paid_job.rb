class SendFinalReminderJob < Job
  attr_accessor :user_id, :pro_username, :reset_token

  def initialize(user_id, pro_username, reset_token)
    self.user_id = user_id
    self.pro_username = pro_username
    self.reset_token = reset_token
  end

  def perform
    UserMailer.final_reminder_paid(user_id, pro_username, reset_password_token).deliver
    TrackMixpanelEventJob.submit_job('Final Reminder Paid Sent', user_id, pro_username: pro_username)
  end

  def self.submit_job(user_id, discount)
    Delayed::Job.enqueue(new(user_id, discount))
  end
end
