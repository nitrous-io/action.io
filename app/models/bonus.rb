class Bonus < ActiveRecord::Base
  belongs_to :user
  attr_accessible

  def self.bonus_info
    {
      sign_up: KeyValue[N2oFill::N2O_SIGN_UP_BONUS],
      invite_friends: KeyValue[N2oFill::N2O_INVITING_WITHIN_LIMITS_BONUS],
      invite_friends_extra: KeyValue[N2oFill::N2O_INVITING_OUTSIDE_LIMITS_BONUS],
      github: KeyValue[N2oFill::N2O_OAUTH_ACTION_BONUS],
      google: KeyValue[N2oFill::N2O_OAUTH_ACTION_BONUS],
      twitter: KeyValue[N2oFill::N2O_OAUTH_ACTION_BONUS],
      facebook: KeyValue[N2oFill::N2O_OAUTH_ACTION_BONUS],
      linkedin: KeyValue[N2oFill::N2O_OAUTH_ACTION_BONUS],
      chrome_app: KeyValue[N2oFill::N2O_INSTALL_CHROME_APP_BONUS],
      twitter_follow: KeyValue[N2oFill::N2O_TWITTER_FOLLOW_BONUS],
      tweet_sent: KeyValue[N2oFill::N2O_TWEET_SENT_BONUS],
      business_survey: KeyValue[N2oFill::N2O_BUSINESS_SURVEY_BONUS],
      user_survey_1: KeyValue[N2oFill::N2O_USER_SURVEY_1_BONUS],
      upgrade_account: '600-5000'
    }
  end
end
