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

  before_save :ensure_authentication_token

  def password_required?
    (authentications.empty? || !password.blank?) && super
  end

  def apply_omniauth_hash(hash={})
    if info_hash = hash['info']
      self.username  ||= info_hash['nickname']
      self.email     ||= info_hash['email']
      self.full_name ||= info_hash['name']
    end
    authentication = authentications.build
    authentication.apply_omniauth_hash(hash)
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      omniauth_hash = session['devise.omniauth_hash']
      if omniauth_hash.present?
        user.apply_omniauth_hash(omniauth_hash)
      end
    end
  end

  def token_for(provider)
    authentications.where(provider: provider).pluck('authentications.token').first
  end

  def as_json(options=nil, override=false)
    options = (options || {}).merge(only: [
      'id',
      'username',
      'email',
      'full_name',
      'authentication_token',
      'created_at',
      'updated_at'
    ]) unless override
    super(options).merge('authentications' => authentications.as_json)
  end
end
