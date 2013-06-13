class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :recoverable
  devise :database_authenticatable, :omniauthable, :registerable,
         :rememberable, :trackable, :validatable, :token_authenticatable,
         :recoverable

  # Setup accessible attributes for your model
  attr_accessible :username, :email, :full_name, :password, :password_confirmation, :remember_me, :invite_code, :login
  attr_accessor   :login, :validate_confirmation

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

  before_save :ensure_authentication_token

  delegate :can?, :cannot?, :to => :ability

  BOX_LIMIT = 3

  def missing_authentications?
    authentications.empty? || validate_confirmation
  end

  def ability
    @ability ||= Ability.new(self)
  end

  def activated?
    received_invites.accepted.any?
  end

  def reset_username_and_password(params)
    self.validate_confirmation = true
    self.username = params[:username]
    self.password = params[:password]
    self.password_confirmation = params[:password]
    self.save
  end

  # request an invite for the user
  # if the user already had an invite, this will not create a new invite
  #
  # ip - optional ip that the current user is in. This will be saved together
  # with the invite
  #
  # return the invite that user has
  def request_invite(ip=nil)
    if (dupe_invite = Invite.find_by_email(email)).present?
      return dupe_invite
    end

    invite = Invite.new.tap do |i|
      i.email = email
      i.ip = ip
      i.save
    end

    if invite.persisted?
      Delayed::Job.enqueue(GeocodeInviteJob.new(invite.id))
    end

    if ENV['AUTO_INVITE'] == 'true'
      invite.activate!
      InviteMailer.delay.send_invite(invite.id)
    end

    invite
  end

  def create_box(box_attrs)
    box = Box.new(
      name: box_attrs[:name],
      memory: box_attrs[:memory],
      storage: box_attrs[:storage]
    )

    if can? :create, Box
      box.owner = self

      if box_attrs[:box_template_id]
        box_template = BoxTemplate.where(id: box_attrs[:box_template_id], enabled: true).first
        box.box_template = (box_template.try(:admin?) && !self.admin?) ? nil : box_template
      end

      box.region = Region.where(id: box_attrs[:region_id].to_s, enabled: true).first if box_attrs[:region_id]
      box.save
    else
      box.errors.add :base, "You can only create #{BOX_LIMIT} #{'box'.pluralize(BOX_LIMIT)} during the private beta period."
    end

    box
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

  def received_invites
    Invite.where('email = ? OR (invite_code = ? AND invite_code IS NOT NULL)', email, invite_code)
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

  def max_n2o
    n2o_fills.sum('amount')
  end

  def used_n2o
    n2o_allocations.allocated.sum('amount')
  end

  def free_n2o
    max_n2o - used_n2o
  end
end
