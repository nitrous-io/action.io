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
      twitter_follow: KeyValue[N2oFill::N2O_TWITTER_FOLLOW_BONUS]
    }
  end
end
