class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable, :timeoutable, :recoverable
  devise :database_authenticatable, :omniauthable, :registerable,
         :rememberable, :trackable, :validatable

  # Setup accessible attributes for your model
  attr_accessible :username, :email, :full_name, :password, :password_confirmation, :remember_me

  has_many :authentications, dependent: :destroy
  has_many :box_admins, dependent: :destroy
  has_many :boxes, through: :box_admins
  has_many :owned_boxes, class_name: 'Box', foreign_key: 'owner_id', dependent: :nullify

  validates :username,  presence: true, uniqueness: true, length: { in: (4..20) }
  validates :email,     presence: true, uniqueness: true
  validates :full_name, presence: true, length: { in: (1..40) }

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
end
