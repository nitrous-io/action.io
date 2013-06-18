class Invite < ActiveRecord::Base
  attr_accessible :email

  validates_presence_of :email, :inviting_user_id
  validates_uniqueness_of :email, scope: :inviting_user_id
  validates_format_of :email, with: NitrousIO::EMAIL_REGEX

  before_validation :clean_email

  belongs_to :inviting_user, class_name: 'User'
  belongs_to :invited_user, class_name: 'User'

  scope :activated,      lambda { where("state = ?", 'activated')                                  }
  scope :accepted,       lambda { where("state = ?", 'accepted')                                   }
  scope :needs_reminder, lambda { activated.where("created_at < ? AND (last_reminded_at IS NULL OR last_reminded_at < ?)", 2.weeks.ago, 2.weeks.ago) }

  state_machine initial: :activated do
    event(:accept)    { transition  :activated  => :accepted   }

    after_transition on: :accept,   do: :update_accepted_at
    after_transition on: :accept,   do: :update_accepted_invites
  end

  def needs_reminder?
    self.activated? && self.created_at < 2.weeks.ago && (self.last_reminded_at.nil? || self.last_reminded_at < 2.weeks.ago)
  end

  protected
  def clean_email
    self.email = self.email.strip.downcase if self.email
  end

  def update_accepted_at
    self.update_attribute :accepted_at, Time.now
  end

  def update_accepted_invites
    total_accepted_invites = Invite.where(inviting_user_id: self.inviting_user_id, referral_code: referral_code, state: 'accepted').count

    inviting_user.update_attribute(:accepted_invites, total_accepted_invites)

    if inviting_user.accepted_invites <= inviting_user.available_invites
      n2o_fill = inviting_user.n2o_fills.build
      n2o_fill.kind = N2oFill::Kind::INVITING_USER_BONUS
      n2o_fill.description = N2oFill::N2O_INVITING_WITHIN_LIMITS_BONUS
      n2o_fill.amount = KeyValue[N2oFill::N2O_INVITING_WITHIN_LIMITS_BONUS] || 0
      n2o_fill.save
    end

    if invited_user.present?
      n2o_fill = invited_user.n2o_fills.build
      n2o_fill.kind = N2oFill::Kind::INVITED_USER_SIGNUP_BONUS
      n2o_fill.description = N2oFill::N2O_INVITED_SIGNUP_BONUS
      n2o_fill.amount = KeyValue[N2oFill::N2O_INVITED_SIGNUP_BONUS] || 0
      n2o_fill.save
    end

  end
end
