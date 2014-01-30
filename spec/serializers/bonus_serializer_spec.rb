require 'spec_helper'

describe BonusSerializer do
  let!(:bonus) { create :bonus, accepted_invite: Time.now, invite_friends: 1.day.ago, github: 2.day.ago, twitter: 3.day.ago, facebook: 4.day.ago, linkedin: 5.day.ago, google: 6.days.ago, chrome_app: 7.days.ago, twitter_follow: 8.days.ago, tweet_sent: 9.days.ago, business_survey: 10.days.ago, user_survey_1: 11.days.ago }

  subject { bonus.serialize_as_json }

  it 'has every field' do
    hash = JSON.parse(subject)['bonus']
    expect(hash.delete 'id').to eq bonus.id
    expect(DateTime.parse(hash.delete 'invite_friends' ).to_i).to eq bonus.invite_friends.to_i
    expect(DateTime.parse(hash.delete 'github'         ).to_i).to eq bonus.github.to_i
    expect(DateTime.parse(hash.delete 'twitter'        ).to_i).to eq bonus.twitter.to_i
    expect(DateTime.parse(hash.delete 'facebook'       ).to_i).to eq bonus.facebook.to_i
    expect(DateTime.parse(hash.delete 'linkedin'       ).to_i).to eq bonus.linkedin.to_i
    expect(DateTime.parse(hash.delete 'google'         ).to_i).to eq bonus.google.to_i
    expect(DateTime.parse(hash.delete 'accepted_invite').to_i).to eq bonus.accepted_invite.to_i
    expect(DateTime.parse(hash.delete 'chrome_app'     ).to_i).to eq bonus.chrome_app.to_i
    expect(DateTime.parse(hash.delete 'twitter_follow' ).to_i).to eq bonus.twitter_follow.to_i
    expect(DateTime.parse(hash.delete 'tweet_sent'     ).to_i).to eq bonus.tweet_sent.to_i
    expect(DateTime.parse(hash.delete 'business_survey').to_i).to eq bonus.business_survey.to_i
    expect(DateTime.parse(hash.delete 'user_survey_1'  ).to_i).to eq bonus.user_survey_1.to_i
    expect(hash).to be_empty
  end
end
