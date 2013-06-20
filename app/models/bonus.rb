class Bonus < ActiveRecord::Base
  belongs_to :user
  attr_accessible

  def self.available_bonuses
    {
      invite_friends: KeyValue[N2oFill::N2O_INVITING_WITHIN_LIMITS_BONUS],
      github:   KeyValue[N2oFill::N2O_OAUTH_ACTION_BONUS],
      google:   KeyValue[N2oFill::N2O_OAUTH_ACTION_BONUS],
      twitter:  KeyValue[N2oFill::N2O_OAUTH_ACTION_BONUS],
      facebook: KeyValue[N2oFill::N2O_OAUTH_ACTION_BONUS],
      linkedin: KeyValue[N2oFill::N2O_OAUTH_ACTION_BONUS]
    }
  end
end
