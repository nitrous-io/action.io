class TrackTwitterInfoOnMixpanelJob < Job
  attr_accessor :user_id

  def initialize(user_id)
    self.user_id = user_id
  end

  def perform
    user = User.find user_id
    twitter = TwitterHandler.new user

    twitter_followers_count = twitter.followers_count
    twitter_handle = twitter.handle

    if twitter_followers_count && twitter_handle
      mixpanel = Mixpanel::Tracker.new ENV['MIXPANEL_TOKEN']
      mixpanel.set user.email, { 'twitter_followers' => twitter_followers_count,
                                 'twitter_handle'    => twitter_handle }
    end
  end

  def self.submit_job(user_id)
    Delayed::Job.enqueue(self.new(user_id))
  end
end
