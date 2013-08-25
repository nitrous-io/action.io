class N2oFill < ActiveRecord::Base
  # Regular Sign Up
  N2O_SIGN_UP_BONUS                   = 'n2o_signup_bonus'.freeze
  # When a user U2 accepts an invite from user U1 then U2 gets a signup bonus
  N2O_SIGN_UP_BONUS_EXTRA             = 'n2o_signup_bonus_extra'.freeze
  # When a user U2 accepts an invite from user U1 and U1 hasn't invited that many people, then U1 gets an N2O_INVITING_WITHIN_LIMITS_BONUS
  N2O_INVITING_WITHIN_LIMITS_BONUS    = 'n2o_fill_inviting_user_within_limits'.freeze
  # When a user U2 accepts an invite from user U1 and U1 has invited a lot of people, then U1 gets an N2O_INVITING_WITHIN_LIMITS_BONUS
  N2O_INVITING_OUTSIDE_LIMITS_BONUS   = 'n2o_fill_inviting_user_outside_limits'.freeze
  # When a user U2 accepts an invite from user U1 then U2 gets a signup bonus
  N2O_INVITED_SIGNUP_BONUS            = 'n2o_fill_invited_user'.freeze
  # When a user connects oauth channel (github/google) he gets a bonus
  N2O_OAUTH_ACTION_BONUS              = 'n2o_oauth_action_bonus'.freeze
  # When a user installs a chrome application for the first time.
  N2O_INSTALL_CHROME_APP_BONUS        = "n2o_chrome_app_bonus".freeze
  # When a user follows @nitrousio on Twitter for the first time.
  N2O_TWITTER_FOLLOW_BONUS            = "n2o_twitter_follow_bonus".freeze
  # When a user sends a tweet for the first time.
  N2O_TWEET_SENT_BONUS                = "n2o_tweet_sent_bonus".freeze

  belongs_to :user
  belongs_to :resource, polymorphic: true

  module Kind
    FAVOR = 0
    SIGN_UP = 1
    INVITING_USER_BONUS = 2
    INVITED_USER_SIGNUP_BONUS = 3
    OAUTH_GITHUB_CONNECT = 4
    OAUTH_GOOGLE_CONNECT = 5
    OAUTH_LINKEDIN_CONNECT = 6
    INSTALL_CHROME_APP = 7
    OAUTH_TWITTER_CONNECT = 8
    OAUTH_FACEBOOK_CONNECT = 9
    TWITTER_FOLLOW = 10
    TWEET_SENT = 11
    PURCHASE = 12
  end

  after_save do
    user.update_balance!
    notify_user!
  end

  def invitee_email
    resource.try(:email)
  end

  private
  def notify_user!
    UserMailer.delay.n2o_bonus_alert(self.id) if kind == Kind::INVITING_USER_BONUS
  end
end
