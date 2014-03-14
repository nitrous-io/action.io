require 'digest/md5'

class UserSerializer < ActiveModel::Serializer
  attributes :id, :username, :email, :full_name, :created_at,
    :admin, :max_n2o, :used_n2o, :intro_seen, :referral_link, :confirmed_at,
    :rewardable_invites_count, :gravatar_hash, :subscription_pending, :coupon,
    :team_plans_enabled, :delinquent_at

  has_many :authentications
  has_one :user_profile
  has_one :billing_profile
  has_one :subscription

  def referral_link
    join_shortcut_path(ref: object.referral_code)
  end

  def gravatar_hash
    email_address = object.email.downcase
    Digest::MD5.hexdigest(email_address)
  end

  def coupon
    return nil unless object.coupon_code

    if coupon = Coupon.active.find_by_code(object.coupon_code)
      coupon.as_json(only: [ :code, :description, :percent_off ], root: false)
    end
  end

  def is_scope_self?
    scope == object
  end

  alias_method :include_admin?,                 :is_scope_self?
  alias_method :include_email?,                 :is_scope_self?
  alias_method :include_authentications?,       :is_scope_self?
  alias_method :include_max_n2o?,               :is_scope_self?
  alias_method :include_used_n2o?,              :is_scope_self?
  alias_method :include_intro_seen?,            :is_scope_self?
  alias_method :include_team_plans_enabled?,    :is_scope_self?
  alias_method :include_subscription_pending?,  :is_scope_self?
  alias_method :include_referral_link?,         :is_scope_self?
  alias_method :include_confirmed_at?,          :is_scope_self?
  alias_method :include_user_profile?,          :is_scope_self?
  alias_method :include_billing_profile?,       :is_scope_self?
  alias_method :include_subscription?,          :is_scope_self?
  alias_method :include_coupon?,                :is_scope_self?
  alias_method :include_rewardable_invites_count?, :is_scope_self?
  alias_method :include_delinquent_at?,         :is_scope_self?
end
