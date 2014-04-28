class Invite < ActiveRecord::Base
  INVITE_MAX_REWARDABLE                 = 'invite_max_rewardable'.freeze

  attr_accessible :email

  validates_presence_of :inviting_user_id
  validates_presence_of :email, message: "Email can't be blank"
  validates_uniqueness_of :email, scope: :inviting_user_id, message: 'User is already invited'
  validates_format_of :email, with: Devise.email_regexp, message: 'Email is invalid'
  validates_with  ::EmailValidator

  before_validation :clean_email

  belongs_to :inviting_user, class_name: 'User'
  belongs_to :invited_user, class_name: 'User'

  has_one :n2o_fill, as: :resource

  scope :activated,      -> { where("state = ?", 'activated')                                  }
  scope :accepted,       -> { where("state = ?", 'accepted')                                   }
  scope :needs_reminder, -> { activated.where("created_at < ? AND (last_reminded_at IS NULL OR last_reminded_at < ?)", 2.weeks.ago, 2.weeks.ago) }

  state_machine initial: :activated do
    event(:accept) { transition :activated  => :accepted }

    after_transition on: :accept, do: :update_accepted_at
    after_transition on: :accept, do: :update_accepted_invites
    after_transition on: :accept, do: :track_accepted_invite_on_mixpanel
  end

  def needs_reminder?
    self.activated? && self.created_at < 2.weeks.ago && (self.last_reminded_at.nil? || self.last_reminded_at < 2.weeks.ago)
  end

  def n2o_earned
    n2o_fill.try(:amount)
  end

  protected
  def clean_email
    self.email = self.email.strip.downcase if self.email
  end

  def update_accepted_at
    self.update_attribute :accepted_at, Time.now
  end

  def update_accepted_invites
    total_accepted_invites = Invite.where(inviting_user_id: self.inviting_user_id,
                                          referral_code: referral_code,
                                          state: 'accepted').count

    SetMixpanelPropertyJob.submit_job(inviting_user.id, :accepted_invites, total_accepted_invites)

    inviting_user.update_attribute(:accepted_invites, total_accepted_invites)
    bonus = inviting_user.bonus

    unless bonus.invite_friends
      SetMixpanelPropertyJob.submit_job(inviting_user.id, :invited_friends, true)
      bonus.update_attribute(:invite_friends, Time.now)
    end

    kind, description, must_fill_n2o, reusing_deleted_email = nil, nil, true, false

    if User.only_deleted.find_by_email(invited_user.email)
      must_fill_n2o = false
      reusing_deleted_email = true
    elsif inviting_user.accepted_invites <= inviting_user.rewardable_invites_count
      kind = N2oFill::Kind::INVITING_USER_BONUS
      description = N2oFill::N2O_INVITING_WITHIN_LIMITS_BONUS
    elsif inviting_user.accepted_invites <= KeyValue[Invite::INVITE_MAX_REWARDABLE]
      kind = N2oFill::Kind::INVITING_USER_BONUS
      description = N2oFill::N2O_INVITING_OUTSIDE_LIMITS_BONUS
    else
      must_fill_n2o = false
    end

    if must_fill_n2o
      inviting_user.fill_n2o!(KeyValue[description] || 0,
                              kind,
                              resource:self,
                              description: description)
    end

    if invited_user.present? && !reusing_deleted_email
      description = N2oFill::N2O_INVITED_SIGNUP_BONUS
      value = inviting_user.referral_n2o || KeyValue[description] || 0

      kind = N2oFill::Kind::INVITED_USER_SIGNUP_BONUS

      invited_user.fill_n2o!(value,
                             kind,
                             description: description)
    end

  end

  def track_accepted_invite_on_mixpanel
    TrackMixpanelEventJob.submit_job('Invite Accepted', self.invited_user_id)
  end
end
