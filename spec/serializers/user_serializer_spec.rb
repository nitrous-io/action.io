require 'spec_helper'
require 'digest/md5'

describe UserSerializer do
  include Rails.application.routes.url_helpers
  let!(:authentication) { create :authentication }
  let!(:billing_profile) { create :billing_profile }
  let!(:user) { create :user, authentications: [authentication], billing_profile: billing_profile, max_n2o: 10, used_n2o: 20, intro_seen: true, rewardable_invites_count: 5, confirmed_at: Time.now }
  let!(:user_profile) { create :user_profile, user: user }

  context 'when scope is the same user' do
    subject { user.serialize_as_json scope: user, url_options: url_options }

    it 'has users fields' do
      hash = JSON.parse(subject)['user']
      hash.delete('id').should == user.id
      hash.delete('admin').should == user.admin
      hash.delete('username').should == user.username
      hash.delete('email').should == user.email
      hash.delete('full_name').should == user.full_name
      hash.delete('max_n2o').should eq user.max_n2o
      hash.delete('used_n2o').should eq user.used_n2o
      hash.delete('intro_seen').should eq user.intro_seen
      hash.delete('created_at').should eq user.created_at.as_json
      hash.delete('confirmed_at').should eq user.confirmed_at.as_json
      hash.delete('authentications').should ==
        [JSON.parse(authentication.serialize_as_json)['authentication']]
      hash.delete('user_profile').should == JSON.parse(user_profile.serialize_as_json)['user_profile']
      hash.delete('billing_profile').should ==
        JSON.parse(billing_profile.serialize_as_json)['billing_profile']
      hash.delete('referral_link').should eq join_shortcut_path(ref: user.referral_code)
      hash.delete('gravatar_hash').should eq Digest::MD5.hexdigest(user.email)
      hash.delete('rewardable_invites_count').should eq user.rewardable_invites_count
      hash.should be_empty
    end
  end

  context 'when scope is a different user' do
    let(:other_user) { create :user }
    subject { user.serialize_as_json scope: other_user, url_options: url_options }

    it 'has id, username, full_name, and created_at' do
      hash = JSON.parse(subject)['user']
      hash.delete('id'       ).should == user.id
      hash.delete('username' ).should == user.username
      hash.delete('full_name').should == user.full_name
      hash.delete('gravatar_hash').should eq Digest::MD5.hexdigest(user.email)
      hash.delete('created_at').should eq(user.created_at.as_json)
      hash.should be_empty
    end
  end

  context 'when scope is not provided' do
    subject { user.serialize_as_json url_options: url_options }

    it 'has id, username, full_name, and created_at' do
      hash = JSON.parse(subject)['user']
      hash.delete('id'       ).should == user.id
      hash.delete('username' ).should == user.username
      hash.delete('full_name').should == user.full_name
      hash.delete('gravatar_hash').should eq Digest::MD5.hexdigest(user.email)
      hash.delete('created_at').should eq(user.created_at.as_json)
      hash.should be_empty
    end
  end
end
