class UserSerializer < ActiveModel::Serializer
  attributes :id, :username, :email, :full_name, :available_invites, :created_at, :admin
  has_many :authentications

  def is_scope_self?
    scope == object
  end

  alias_method :include_admin?,             :is_scope_self?
  alias_method :include_email?,             :is_scope_self?
  alias_method :include_available_invites?, :is_scope_self?
  alias_method :include_authentications?,   :is_scope_self?
end
