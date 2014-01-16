class TrackMixpanelEventJob < Job
  attr_accessor :event, :user_id, :properties

  def initialize(event, user_id = nil, properties={})
    self.event = event
    self.user_id = user_id
    self.properties = properties || {}
  end

  def perform
    if self.user_id.present?
      user = User.find_by id: self.user_id
      if user
        bonus = user.bonus

        self.properties.merge! email: user.email,
                               distinct_id: user.email,
                               free_n2o: user.free_n2o,
                               is_github_authenticated: bonus.github.present?,
                               is_twitter_authenticated: bonus.twitter.present?,
                               is_facebook_authenticated: bonus.facebook.present?,
                               is_google_authenticated: bonus.google.present?,
                               is_linkedin_authenticated: bonus.linkedin.present?,
                               invited_friends: bonus.invite_friends.present?,
                               twitter_follow: bonus.twitter_follow.present?,
                               tweet_sent: bonus.tweet_sent.present?,
                               accepted_invites: user.accepted_invites

      else
        deleted_user = DeletedUser.find_by_user_id(self.user_id)
        self.properties.merge! email: deleted_user.email, distinct_id: deleted_user.email
      end
    end

    mixpanel = Mixpanel::Tracker.new ENV['MIXPANEL_TOKEN']
    mixpanel.track event, properties
  end

  def self.submit_job(event, user_id = nil, properties = {})
    Delayed::Job.enqueue(self.new(event, user_id, properties))
  end
end


