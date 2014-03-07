require 'spec_helper'
require 'digest/md5'

describe UserSerializer do
  include Rails.application.routes.url_helpers
  let!(:authentication) { create :authentication }
  let!(:billing_profile) { create :billing_profile }
  let!(:coupon) { create :coupon, code: 'deal50', percent_off: 50, description: '50% off for 2 months' }
  let!(:user) { create :user, authentications: [authentication], billing_profile: billing_profile, max_n2o: 10, used_n2o: 20, intro_seen: true, team_plans_enabled: false, rewardable_invites_count: 5, confirmed_at: Time.now, coupon_code: 'deal50' }
  let!(:user_profile) { create :user_profile, user: user }
  let!(:subscription) { create :subscription, user: user }

  context 'when scope is the same user' do
    subject { user.serialize_as_json scope: user, url_options: url_options }

    it 'has users fields' do
      hash = JSON.parse(subject)['user']
      expect(hash.delete('id')).to eq(user.id)
      expect(hash.delete('admin')).to eq(user.admin)
      expect(hash.delete('username')).to eq(user.username)
      expect(hash.delete('email')).to eq(user.email)
      expect(hash.delete('full_name')).to eq(user.full_name)
      expect(hash.delete('max_n2o')).to eq user.max_n2o
      expect(hash.delete('used_n2o')).to eq user.used_n2o
      expect(hash.delete('intro_seen')).to eq user.intro_seen
      expect(hash.delete('team_plans_enabled')).to eq user.team_plans_enabled
      expect(hash.delete('delinquent_at')).to eq user.delinquent_at
      expect(hash.delete('created_at')).to eq user.created_at.as_json
      expect(hash.delete('confirmed_at')).to eq user.confirmed_at.as_json
      expect(hash.delete('subscription_pending')).to eq user.subscription_pending.as_json
      expect(hash.delete('authentications')).to eq(
        [JSON.parse(authentication.serialize_as_json)['authentication']]
      )
      expect(hash.delete('user_profile')).to eq(JSON.parse(user_profile.serialize_as_json)['user_profile'])
      expect(hash.delete('billing_profile')).to eq(
        JSON.parse(billing_profile.serialize_as_json)['billing_profile']
      )
      expect(hash.delete('subscription')).to eq(
        JSON.parse(subscription.serialize_as_json)['subscription']
      )

      expect(hash.delete('referral_link')).to eq join_shortcut_path(ref: user.referral_code)
      expect(hash.delete('gravatar_hash')).to eq Digest::MD5.hexdigest(user.email)
      expect(hash.delete('rewardable_invites_count')).to eq user.rewardable_invites_count

      expect(hash.delete('coupon')).to eq(
        { code: 'deal50', description: '50% off for 2 months', percent_off: 50 }.as_json
      )
      expect(hash).to be_empty
    end
  end

  context 'when scope is a different user' do
    let(:other_user) { create :user }
    subject { user.serialize_as_json scope: other_user, url_options: url_options }

    it 'has id, username, full_name, and created_at' do
      hash = JSON.parse(subject)['user']
      expect(hash.delete('id'       )).to eq(user.id)
      expect(hash.delete('username' )).to eq(user.username)
      expect(hash.delete('full_name')).to eq(user.full_name)
      expect(hash.delete('gravatar_hash')).to eq Digest::MD5.hexdigest(user.email)
      expect(hash.delete('created_at')).to eq(user.created_at.as_json)
      expect(hash).to be_empty
    end
  end

  context 'when scope is not provided' do
    subject { user.serialize_as_json url_options: url_options }

    it 'has id, username, full_name, and created_at' do
      hash = JSON.parse(subject)['user']
      expect(hash.delete('id'       )).to eq(user.id)
      expect(hash.delete('username' )).to eq(user.username)
      expect(hash.delete('full_name')).to eq(user.full_name)
      expect(hash.delete('gravatar_hash')).to eq Digest::MD5.hexdigest(user.email)
      expect(hash.delete('created_at')).to eq(user.created_at.as_json)
      expect(hash).to be_empty
    end
  end
end
