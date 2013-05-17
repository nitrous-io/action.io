class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :recoverable
  devise :database_authenticatable, :omniauthable, :registerable,
         :rememberable, :trackable, :validatable, :token_authenticatable,
         :recoverable

  # Setup accessible attributes for your model
  attr_accessible :username, :email, :full_name, :password, :password_confirmation, :remember_me, :invite_code, :login
  attr_accessor   :login

  has_many :authentications, dependent: :destroy
  has_many :box_users,       dependent: :destroy
  has_many :boxes,           through:   :box_users
  has_many :owned_boxes,     dependent: :nullify, class_name: 'Box', foreign_key: 'owner_id'
  has_many :public_keys,     dependent: :destroy
  has_many :oauth_applications, class_name: 'Doorkeeper::Application', as: :owner, dependent: :destroy
  has_many :owned_invites,   dependent: :nullify, class_name: 'Invite', foreign_key: 'inviting_user_id'

  validates :username,  presence: true, uniqueness: true, length: { in: (4..20) }
  validates :email,     presence: true, uniqueness: true
  validates :full_name, length: { in: (0..40), allow_nil: true }

  before_save :ensure_authentication_token

  delegate :can?, :cannot?, :to => :ability

  BOX_LIMIT = 3

  def ability
    @ability ||= Ability.new(self)
  end

  def activated?
    received_invitations.accepted.any?
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
    box = Box.new(name: box_attrs[:name])

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

  def password_required?
    (authentications.empty? || !password.blank?) && super
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

  def owned_invite_with_email(email)
    owned_invites.where(email: email).first
  end

  def received_invitations
    Invite.where(email: email)
  end

  def mark_collaboration_invites_as_accepted!
    CollaborationInvite.activated.where(email: self.email).each { |ci| ci.accept! }
  end

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup

    if login = conditions.delete(:login)
      where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions).first
    end
  end
end
