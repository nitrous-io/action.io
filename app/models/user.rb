class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :recoverable
  devise :database_authenticatable, :omniauthable, :registerable,
         :rememberable, :trackable, :validatable, :token_authenticatable,
         :recoverable

  # Setup accessible attributes for your model
  attr_accessible :username, :email, :full_name, :password, :password_confirmation, :remember_me, :invite_code

  has_many :authentications, dependent: :destroy
  has_many :box_admins,      dependent: :destroy
  has_many :boxes,             through: :box_admins
  has_many :owned_boxes,     dependent: :nullify, class_name: 'Box', foreign_key: 'owner_id', dependent: :nullify
  has_many :public_keys,     dependent: :destroy
  has_many :oauth_applications, class_name: 'Doorkeeper::Application', as: :owner, dependent: :destroy

  validates :username,  presence: true, uniqueness: true, length: { in: (4..20) }
  validates :email,     presence: true, uniqueness: true
  validates :full_name, length: { in: (1..40), allow_nil: true }

  validates_each :invite_code, on: :create, unless: :admin? do |user, _attr, value|
    invite = Invite.find_by_email(user.email)

    if invite.blank? || value.blank? || invite.invite_code != value
      user.errors.add _attr, "Please enter the invite code that you received in your invitation email."
    end
  end

  before_save :ensure_authentication_token

  after_create do |user|
    invite = Invite.find_by_email(user.email)
    invite.accept! if invite.present?
  end

  def password_required?
    (authentications.empty? || !password.blank?) && super
  end

  def token_for(provider)
    authentications.where(provider: provider).pluck('authentications.token').first
  end
end
