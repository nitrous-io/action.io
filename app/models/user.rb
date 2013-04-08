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

  validates_each :invite_code, on: :create, unless: :admin? do |user, _attr, value|
    if value.blank? || user.received_invitations.where(invite_code: value).empty?
      user.errors.add _attr, "Please enter the invite code that you received in your invitation email."
    end
  end

  before_save :ensure_authentication_token

  after_create do |user|
    user.received_invitations.each(&:accept!)
  end

  BOX_LIMIT = 3

  def create_box(box_attrs)
    box = Box.new(name: box_attrs[:name])

    if self.boxes.unterminated.count < BOX_LIMIT || self.admin?
      box.owner = self

      if box_attrs[:box_template_id]
        box_template = BoxTemplate.where(id: box_attrs[:box_template_id], enabled: true).first
        box.box_template = (box_template.try(:admin?) && !self.admin?) ? nil : box_template
      end

      box.region = Region.where(id: box_attrs[:region_id].to_s, enabled: true).first if box_attrs[:region_id]
      box.save

      if box.valid?
        box.enqueue_provision!
        IncrementMixpanelPropertyJob.submit_job(self.id, :boxes_created, 1)
        TrackMixpanelEventJob.submit_job('Box Created', self.id)
      end
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

  def self.find_first_by_auth_conditions(warden_conditions)
    conditions = warden_conditions.dup

    if login = conditions.delete(:login)
      where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions).first
    end
  end
end
