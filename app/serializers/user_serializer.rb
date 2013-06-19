class UserSerializer < ActiveModel::Serializer
  attributes :id, :username, :email, :full_name, :available_invites, :created_at,
    :admin, :max_n2o, :used_n2o, :intro_seen, :referral_link
  has_many :authentications

  def referral_link
    join_shortcut_url(ref: object.referral_code, host: ENV['RAILS_HOST_FULL'])
  end

  def is_scope_self?
    scope == object
  end

  alias_method :include_admin?,             :is_scope_self?
  alias_method :include_email?,             :is_scope_self?
  alias_method :include_available_invites?, :is_scope_self?
  alias_method :include_authentications?,   :is_scope_self?
  alias_method :include_max_n2o?,           :is_scope_self?
  alias_method :include_used_n2o?,          :is_scope_self?
  alias_method :include_intro_seen?,        :is_scope_self?
  alias_method :include_referral_link?,     :is_scope_self?
end
