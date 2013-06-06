class UserSerializer < ActiveModel::Serializer
  attributes :id, :username, :email, :full_name, :bio, :location, :company, :languages,
             :available_invites, :created_at, :admin, :actions, :activated, :intro_completed
  has_many :authentications

  def is_scope_self?
    scope == object
  end

  def actions
    {
      create_box: object.can?(:create, Box)
    }
  end

  def activated
    object.activated?
  end

  alias_method :include_admin?,             :is_scope_self?
  alias_method :include_email?,             :is_scope_self?
  alias_method :include_available_invites?, :is_scope_self?
  alias_method :include_authentications?,   :is_scope_self?
  alias_method :include_actions?,           :is_scope_self?
  alias_method :include_activated?,         :is_scope_self?
  alias_method :include_intro_completed?,   :is_scope_self?
end
