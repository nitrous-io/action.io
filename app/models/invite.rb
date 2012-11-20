class Invite < ActiveRecord::Base
  attr_accessible :email

  validates_presence_of :email
  validates_uniqueness_of :email, scope: :inviting_user_id
  validates_format_of :email, with: /\A^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$\z/i

  before_validation :strip_email

  belongs_to :inviting_user, :class_name => 'User'

  scope :pending,   lambda { where("state = ?", 'pending') }
  scope :activated, lambda { where("state = ?", 'activated') }
  scope :accepted,  lambda { where("state = ?", 'accepted') }

  state_machine initial: :pending do
    event(:activate)  { transition  :pending    => :activated  }
    event(:accept)    { transition  :activated  => :accepted   }

    before_transition :pending => :activated do |invite, transition|
      invite.generate_invite_code!
    end

    after_transition on: :activate, do: :decrement_available_invites
  end

  before_create :set_referral_code

  def generate_invite_code!
    self.update_attribute(:invite_code, SecureRandom.urlsafe_base64(8))
  end

  protected
  def strip_email
    self.email = self.email.strip if self.email
  end

  def set_referral_code
    self.referral_code = SecureRandom.urlsafe_base64(8) if self.referral_code.blank?
  end

  def decrement_available_invites
    self.inviting_user.decrement!(:available_invites) if self.inviting_user
  end
end
