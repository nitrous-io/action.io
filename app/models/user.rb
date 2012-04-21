class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :recoverable
  devise :database_authenticatable, :omniauthable, :registerable,
         :rememberable, :trackable, :validatable, :token_authenticatable

  # Setup accessible attributes for your model
  attr_accessible :username, :email, :full_name, :password, :password_confirmation, :remember_me

  has_many :authentications, dependent: :destroy
  has_many :box_admins,      dependent: :destroy
  has_many :boxes,             through: :box_admins
  has_many :owned_boxes,     dependent: :nullify, class_name: 'Box', foreign_key: 'owner_id', dependent: :nullify
  has_many :public_keys,     dependent: :destroy

  validates :username,  presence: true, uniqueness: true, length: { in: (4..20) }
  validates :email,     presence: true, uniqueness: true
  validates :full_name, presence: true, length: { in: (1..40) }

  before_save   :ensure_authentication_token

  def password_required?
    (authentications.empty? || !password.blank?) && super
  end

  def apply_omniauth_hash(hash={})
    info = hash['info']
    if info
      self.username ||= info['nickname']
      self.email ||= info['email']
      self.full_name ||= info['name']
    end
    authentication = authentications.build
    authentication.provider = hash['provider']
    authentication.uid = hash['uid'].to_s
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      omniauth_hash = session['devise.omniauth_hash']
      if omniauth_hash.present?
        user.apply_omniauth_hash(omniauth_hash)
      end
    end
  end

  def as_json(options=nil)
    super((options || {}).merge(only: [:username, :authentication_token, :email]))
  end
end
