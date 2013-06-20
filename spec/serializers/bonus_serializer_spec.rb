require 'spec_helper'

describe BonusSerializer do
  let!(:bonus) { create :bonus, accepted_invite: Time.now, invite_friends: 1.day.ago, github: 2.day.ago, twitter: 3.day.ago, facebook: 4.day.ago, linkedin: 5.day.ago }

  subject { bonus.serialize_as_json }

  it 'has every field' do
    hash = JSON.parse(subject)['bonus']
    expect(hash.delete 'id').to eq bonus.id
    expect(DateTime.parse(hash.delete 'invite_friends' ).to_i).to eq bonus.invite_friends.to_i
    expect(DateTime.parse(hash.delete 'github'         ).to_i).to eq bonus.github.to_i
    expect(DateTime.parse(hash.delete 'twitter'        ).to_i).to eq bonus.twitter.to_i
    expect(DateTime.parse(hash.delete 'facebook'       ).to_i).to eq bonus.facebook.to_i
    expect(DateTime.parse(hash.delete 'linkedin'       ).to_i).to eq bonus.linkedin.to_i
    expect(DateTime.parse(hash.delete 'accepted_invite').to_i).to eq bonus.accepted_invite.to_i
    hash.should be_empty
  end
end
