class Invite < ActiveRecord::Base
  attr_accessible :email

  validates_presence_of :email
  validates_uniqueness_of :email, :scope => :inviting_user_id
  validates_format_of :email, :with => /^[_a-z0-9-]+(\.[_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*(\.[a-z]{2,4})$/

  before_validation :strip_email

  belongs_to :inviting_user, :class_name => 'User'

  scope :pending,   lambda { where("state = ?", 'pending') }
  scope :activated, lambda { where("state = ?", 'activated') }
  scope :accepted,  lambda { where("state = ?", 'accepted') }

  default_scope order("created_at DESC")

  state_machine initial: :pending do
    event(:activate)  { transition  :pending    => :activated  }
    event(:accept)    { transition  :activated  => :accepted   }

    before_transition :pending => :activated do |invite, transition|
      invite.generate_invite_code!
    end
  end

  def generate_invite_code!
    # Just pick the first 7 characters of the SHA
    invite_sha = Digest::SHA1.hexdigest("#{self.email}-#{Time.now.to_i}")[0...7]
    self.update_attribute(:invite_code, invite_sha)
  end

  protected
  def strip_email
    self.email = self.email.strip if self.email
  end
end