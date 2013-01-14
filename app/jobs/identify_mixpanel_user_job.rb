class IdentifyMixpanelUserJob
  attr_accessor :user_id

  def initialize(user_id)
    self.user_id = user_id
  end

  def perform
    user = User.find(self.user_id)

    mixpanel = Mixpanel::Tracker.new ENV['MIXPANEL_TOKEN']
    mixpanel.set user.email,
                 {
                   email: user.email,
                   username: user.username,
                   created: user.created_at.as_json,
                   name: user.full_name,
                   is_github_authenticated: user.token_for('github').present?,
                   boxes_created: user.boxes.unterminated.count,
                   boxes_running: user.boxes.running.count,
                   public_keys: user.public_keys.count
                 }
  end

  def self.submit_job(user_id)
    Delayed::Job.enqueue(self.new(user_id))
  end
end
