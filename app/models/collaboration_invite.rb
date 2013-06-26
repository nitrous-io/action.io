class CollaborationInvite < ActiveRecord::Base
  validates_presence_of :email
  validates_uniqueness_of :email, scope: :box_id
  validates_format_of :email, with: AIO::EMAIL_REGEX

  before_validation :clean_email

  belongs_to  :box

  after_create  :send_invite

  scope :activated,      lambda { where("state = ?", 'activated')                                  }
  scope :accepted,       lambda { where("state = ?", 'accepted')                                   }
  scope :needs_reminder, lambda { activated.where("created_at < :since AND (last_reminded_at IS NULL OR last_reminded_at < :since)", since: 2.weeks.ago) }

  state_machine initial: :activated do
    event(:accept)    { transition  :activated => :accepted }

    after_transition on: :accept,   do: :update_accepted_at
    after_transition on: :accept,   do: :update_box_collaborators
  end

  protected
  def clean_email
    self.email = self.email.strip.downcase if self.email
  end

  def update_accepted_at
    self.update_attribute :accepted_at, Time.now
  end

  def update_box_collaborators
    self.box.add_collaborator(self.email) if box.present?
  end

  def send_invite
    InviteMailer.delay.send_collaboration_invite(self.id)
  end
end
