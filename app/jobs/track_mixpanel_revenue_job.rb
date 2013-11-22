class TrackMixpanelRevenueJob < Job
  attr_accessor :user_id, :amount

  def initialize(user_id, amount, properties={})
    self.user_id = user_id
    self.amount = amount
  end

  def perform
    if self.user_id.present?
      user = User.find(self.user_id)
      mixpanel = Mixpanel::Tracker.new ENV['MIXPANEL_TOKEN']
      mixpanel.track_charge user.email, amount
    end
  end

  def self.submit_job(user_id, amount)
    Delayed::Job.enqueue(self.new(user_id, amount))
  end
end



