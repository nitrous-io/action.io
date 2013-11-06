class IdentifyMixpanelUserJob < Job
  attr_accessor :user_id, :attributes

  def initialize(user_id, attributes = {})
    self.user_id = user_id
    self.attributes = attributes
  end

  def perform
    email = nil
    mixpanel_params = {}

    user = User.find(self.user_id)
    email = user.email
    mixpanel_params = {
                        email: user.email,
                        username: user.username,
                        created: user.created_at.as_json,
                        ip: user.current_sign_in_ip,
                        name: user.full_name,
                        is_github_authenticated: user.token_for('github').present?,
                        boxes_created: user.boxes.unterminated.count,
                        boxes_running: user.boxes.running.count,
                        public_keys: user.public_keys.count
                      }

    distinct_id = attributes.delete('distinct_id')
    mixpanel_params.merge!(attributes)

    mixpanel = Mixpanel::Tracker.new ENV['MIXPANEL_TOKEN']

    mixpanel.alias email, distinct_id: distinct_id if distinct_id
    mixpanel.set email, mixpanel_params
  end

  def self.submit_job(user_id, attributes = {})
    Delayed::Job.enqueue(self.new(user_id, attributes))
  end
end
