require 'spec_helper'

describe Bonus do
  it { should belong_to :user }

  describe '.bonus_info' do
    before do
      KeyValue.create(key: N2oFill::N2O_SIGN_UP_BONUS, value: 155)
      KeyValue.create(key: N2oFill::N2O_INVITING_WITHIN_LIMITS_BONUS, value: 10)
      KeyValue.create(key: N2oFill::N2O_INVITING_OUTSIDE_LIMITS_BONUS, value: 1)
      KeyValue.create(key: N2oFill::N2O_OAUTH_ACTION_BONUS, value: 5)
      KeyValue.create(key: N2oFill::N2O_INSTALL_CHROME_APP_BONUS, value: 4)
      KeyValue.create(key: N2oFill::N2O_TWITTER_FOLLOW_BONUS, value: 8)
      KeyValue.create(key: N2oFill::N2O_TWEET_SENT_BONUS, value: 7)
      KeyValue.create(key: N2oFill::N2O_BUSINESS_SURVEY_BONUS, value: 9)
    end

    it 'returns a hash containing information about bonuses' do
      expect(Bonus.bonus_info).to eq({
        sign_up: 155,
        invite_friends: 10,
        invite_friends_extra: 1,
        github: 5,
        google: 5,
        twitter: 5,
        facebook: 5,
        linkedin: 5,
        chrome_app: 4,
        twitter_follow: 8,
        tweet_sent: 7,
        business_survey: 9,
        upgrade_account: '600-5000'
      })
    end
  end
end
