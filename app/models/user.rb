class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :recoverable
  devise :database_authenticatable, :omniauthable, :registerable,
         :rememberable, :trackable, :validatable, :token_authenticatable,
         :recoverable, :confirmable

  # Setup accessible attributes for your model
  attr_accessible :username, :email, :full_name, :password, :password_confirmation, :remember_me, :login, :referrer_code
  attr_accessor   :login, :validate_confirmation, :referrer_code

  has_many :authentications, dependent: :destroy
  has_many :box_users,       dependent: :destroy
  has_many :boxes,           through:   :box_users
  has_many :owned_boxes,     dependent: :nullify, class_name: 'Box', foreign_key: 'owner_id'
  has_many :public_keys,     dependent: :destroy
  has_many :oauth_applications, class_name: 'Doorkeeper::Application', as: :owner, dependent: :destroy
  has_many :owned_invites,   dependent: :nullify, class_name: 'Invite', foreign_key: 'inviting_user_id'
  has_many :n2o_fills,       dependent: :destroy
  has_many :n2o_allocations, dependent: :destroy

  validates :username,  uniqueness: true, allow_nil: true
  validates :username,  presence: true, length: { in: (4..20) }, if: :missing_authentications?
  validates_exclusion_of :username, in: USERNAME_BLACKLIST
  validates :email,     presence: true, uniqueness: true
  validates :full_name, length: { in: (0..40), allow_nil: true }

  before_save   :ensure_authentication_token
  before_create :set_referral_code!
  after_create  :mark_or_create_invite_as_accepted!

  def confirm!
    super

    # check if there are any previous n2o signup fills
    # (to avoid giving n2o for reconfirmations)
    unless self.n2o_fills.where(kind: N2oFill::Kind::SIGN_UP).any?
      self.give_sign_up_bonus
      self.mark_collaboration_invites_as_accepted!
      UserMailer.delay.welcome(self.email)
    end

    TrackMixpanelEventJob.submit_job('User Confirmed', self.id)
  end

  def missing_authentications?
    authentications.empty? || validate_confirmation
  end

  def reset_username_and_password(params)
    self.validate_confirmation = true
    self.username = params[:username]
    self.password = params[:password]
    self.password_confirmation = params[:password]
    self.save
  end

  def token_for(provider)
    authentications.where(provider: provider).pluck('authentications.token').first
  end

  def visible_boxes
    boxes.where("boxes.terminated_at IS NULL OR terminated_at > ?", 1.day.ago).order("id ASC")
  end

  def able_to_invite?
    self.available_invites > 0
  end

  def able_to_login?
    username.present?
  end

  def owned_invite_with_email(email)
    owned_invites.where(email: email).first
  end

  def mark_collaboration_invites_as_accepted!
    CollaborationInvite.activated.where(email: self.email).each { |ci| ci.accept! }
  end

  def update_omniauth_authentication(data)
    authentication = self.authentications.find_by_provider(data["provider"])
    unless authentication
      authentication = Authentication.new
      authentication.user = self
    end
    authentication.apply_omniauth_hash(data)
    authentication.save!
  end

  # Given data comes back from omniauth hash
  # create a new user with authentication and a random password
  # `username` can be empty here. We expect the user to fill in username before
  # he can login to the site
  def self.create_from_omniauth_data(data)
    user = User.new.tap do |u|
      u.email = data['info']['email']
      u.password = SecureRandom.hex(7)
      u.full_name = data['info']['name']
    end
    authentication = Authentication.new
    authentication.apply_omniauth_hash(data)
    user.authentications << authentication
    user.save
    user
  end

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup

    if login = conditions.delete(:login)
      where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions).first
    end
  end

  def self.clean_orphaned_users(from_time)
    User.where(username: nil).
      where("created_at < ?", from_time).
      destroy_all
  end

  def update_balance!
    self.used_n2o = n2o_allocations.allocated.sum('amount')
    self.max_n2o = n2o_fills.sum('amount')
    save!

    PushCurrentN2oBalanceJob.submit_job(self)
  end

  def set_referral_code!
    self.referral_code = SecureRandom.urlsafe_base64(8) if referral_code.blank?
  end

  def free_n2o
    max_n2o - used_n2o
  end

  def give_sign_up_bonus
    sign_up_bonus = KeyValue[N2oFill::N2O_SIGN_UP_BONUS]
    if sign_up_bonus.present?
      fill = n2o_fills.new
      fill.kind = N2oFill::Kind::SIGN_UP
      fill.amount = sign_up_bonus
      fill.save!
    end
  end

  def mark_or_create_invite_as_accepted!
    if referrer_code
      invite = Invite.where(email: email, referral_code: referrer_code).first

      if invite
        invite.update_attribute(:invited_user_id, self.id)
        invite.accept!
      else
        user = User.find_by_referral_code(referrer_code)
        return unless user

        invite = Invite.new.tap do |i|
          i.email = email
          i.referral_code = referrer_code
          i.inviting_user = user
          i.invited_user = self
          i.save!
        end

        invite.accept!
      end
    end
  end
end
