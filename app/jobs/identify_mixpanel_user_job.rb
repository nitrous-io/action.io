class IdentifyMixpanelUserJob < Job
  attr_accessor :user_id, :invite_id

  def initialize(args)
    self.user_id = args[:user_id]
    self.invite_id = args[:invite_id]
  end

  def perform
    email = nil
    mixpanel_params = {}

    if self.user_id
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
    elsif self.invite_id
      invite = Invite.find(self.invite_id)
      email = invite.email
      mixpanel_params = { email: invite.email }
    end

    if email
      mixpanel = Mixpanel::Tracker.new ENV['MIXPANEL_TOKEN']
      mixpanel.set email, mixpanel_params
    end
  end

  def self.submit_job(args)
    Delayed::Job.enqueue(self.new(args))
  end
end
