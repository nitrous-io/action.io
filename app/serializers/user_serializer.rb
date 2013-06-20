class UserSerializer < ActiveModel::Serializer
  attributes :id, :username, :email, :full_name, :created_at,
    :admin, :max_n2o, :used_n2o, :intro_seen, :referral_link, :confirmed_at,
    :rewardable_invites_count

  has_many :authentications

  def referral_link
    join_shortcut_path(ref: object.referral_code)
  end

  def is_scope_self?
    scope == object
  end

  alias_method :include_admin?,             :is_scope_self?
  alias_method :include_email?,             :is_scope_self?
  alias_method :include_authentications?,   :is_scope_self?
  alias_method :include_max_n2o?,           :is_scope_self?
  alias_method :include_used_n2o?,          :is_scope_self?
  alias_method :include_intro_seen?,        :is_scope_self?
  alias_method :include_referral_link?,     :is_scope_self?
  alias_method :include_rewardable_invites_count?, :is_scope_self?
  alias_method :include_confirmed_at?,      :is_scope_self?
end
