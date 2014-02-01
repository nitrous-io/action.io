class BonusSerializer < ActiveModel::Serializer
  attributes  :id,
              :invite_friends,
              :github,
              :twitter,
              :facebook,
              :linkedin,
              :accepted_invite,
              :google,
              :chrome_app,
              :twitter_follow,
              :tweet_sent,
              :business_survey,
              :user_survey_1
end
