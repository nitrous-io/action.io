class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :recoverable
  devise :database_authenticatable, :omniauthable, :registerable,
         :rememberable, :trackable, :validatable, :token_authenticatable,
         :recoverable

  # Setup accessible attributes for your model
  attr_accessible :username, :email, :full_name, :password, :password_confirmation, :remember_me, :invite_code

  has_many :addons,          through: :addon_admins
  has_many :authentications, dependent: :destroy
  has_many :box_admins,      dependent: :destroy
  has_many :addon_admins,    dependent: :destroy
  has_many :boxes,           through: :box_admins
  has_many :owned_boxes,     dependent: :nullify, class_name: 'Box', foreign_key: 'owner_id'
  has_many :public_keys,     dependent: :destroy
  has_many :oauth_applications, class_name: 'Doorkeeper::Application', as: :owner, dependent: :destroy
  has_many :owned_invites,   dependent: :nullify, class_name: 'Invite', foreign_key: 'inviting_user_id'

  validates :username,  presence: true, uniqueness: true, length: { in: (4..20) }
  validates :email,     presence: true, uniqueness: true
  validates :full_name, length: { in: (0..40), allow_nil: true }

  validates_each :invite_code, on: :create, unless: :admin? do |user, _attr, value|
    if value.blank? || user.received_invitations.where(invite_code: value).empty?
      user.errors.add _attr, "Please enter the invite code that you received in your invitation email."
    end
  end

  before_save :ensure_authentication_token

  after_create do |user|
    user.received_invitations.each(&:accept!)
  end

  def password_required?
    (authentications.empty? || !password.blank?) && super
  end

  def token_for(provider)
    authentications.where(provider: provider).pluck('authentications.token').first
  end

  def functional_boxes
    boxes.where("boxes.terminated_at IS NULL OR terminated_at > ?", 1.day.ago)
  end

  def able_to_invite?
    self.available_invites > 0
  end

  def owned_invite_with_email(email)
    owned_invites.where(email: email).first
  end

  def received_invitations
    Invite.where(email: email)
  end
end
