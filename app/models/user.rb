class User < ActiveRecord::Base

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :recoverable
  devise :database_authenticatable, :omniauthable, :registerable,
         :rememberable, :trackable, :validatable, :token_authenticatable,
         :recoverable, :confirmable

  # Setup accessible attributes for your model
  attr_accessible :username, :email, :full_name, :password, :password_confirmation, :remember_me, :login, :referrer_code, :user_profile_attributes
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
  has_one  :bonus,           dependent: :destroy
  has_one  :user_profile,    dependent: :destroy
  has_one  :billing_profile, dependent: :nullify

  accepts_nested_attributes_for :user_profile

  validates :username,  uniqueness: true, allow_nil: true
  validates :username,  presence: true, length: { in: (2..20) }, if: :missing_authentications?
  validates_format_of :username, with: /\A[a-z0-9][a-z0-9\-]*\z/i,
    message: "may only contain alphanumeric characters or dashes and cannot begin with a dash",
    if: :missing_authentications?
  validates_exclusion_of :username, in: USERNAME_BLACKLIST
  validates :email,     presence: true, uniqueness: true
  validates :full_name, length: { in: (0..40), allow_nil: true }

  validates_with  ::EmailValidator

  before_validation :set_referral_code!

  before_save     :ensure_authentication_token
  before_create   :set_referral_code!

  after_create    :create_or_update_invite!

  before_destroy  :remove_from_mixpanel
  before_destroy  :remove_from_mailchimp

  def confirm!
    return unless super

    # check if there are any previous n2o signup fills
    # (to avoid giving n2o for reconfirmations)
    unless self.n2o_fills.where(kind: N2oFill::Kind::SIGN_UP).any?
      give_sign_up_bonus
      mark_invite_as_accepted!
      self.mark_collaboration_invites_as_accepted!
    end

    MailchimpJob.submit_job('subscribe', Settings.mailchimp_monthly_newsletter_list_id, user_id: self.id)
    MailchimpJob.submit_job('subscribe', Settings.mailchimp_product_announcements_list_id, user_id: self.id)

    TrackMixpanelEventJob.submit_job('User Confirmed', self.id)
    SetMixpanelPropertyJob.submit_job(self.id, :confirmed_at, self.confirmed_at)
  end

  def bonus_with_create
    User.transaction(requires_new: true) do
      bonus = bonus_without_create
      bonus.present? ? bonus : create_bonus
    end
  end
  alias_method_chain :bonus, :create

  def user_profile_with_create
    User.transaction(requires_new: true) do
      user_profile = user_profile_without_create
      user_profile.present? ? user_profile : create_user_profile
    end
  end
  alias_method_chain :user_profile, :create

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

  def visible_boxes(opts = {})
    boxes_relation = opts[:owner] ? owned_boxes : boxes
    boxes_relation.where("boxes.terminated_at IS NULL").order("id ASC")
  end

  def able_to_login?
    username.present?
  end

  def active_for_authentication?
    in_private_beta? ? true : super
  end

  def active_plan
    @active_plan ||= self.try(:billing_profile).try(:active_subscription).try(:plan)
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
    authentication.confirmed = true
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
    save!(validate: false)

    PushCurrentN2oBalanceJob.submit_job(self)
    SetMixpanelPropertyJob.submit_job(self.id, :free_n2o, self.free_n2o)
  end

  def set_referral_code!
    if self.respond_to?(:referral_code=)
      self.referral_code = SecureRandom.urlsafe_base64(8) if referral_code.blank?
    end
  end

  def github
    @github ||= GitHub.new(self)
  end

  def repositories
    # Assume only GitHub repos now. When we support more sources like
    # Bitbucket, self-hosted git, SVN (omg), abstract this out.
    @repositories ||= github.repositories
  end

  def twitter
    @twitter ||= TwitterHandler.new(self)
  end

  def follow_nitrous_on_twitter
    self.twitter.follow
  end

  def send_tweet(message)
    self.twitter.tweet message
  end

  def free_n2o
    max_n2o - used_n2o
  end

  def fill_n2o!(amount, kind, opts = {})
    fill = n2o_fills.new
    fill.kind = kind
    fill.amount = amount
    fill.description = opts[:description]
    fill.resource = opts[:resource]

    fill.save!
  end

  def fill_n2o_for_oauth_action!(provider)
    n2o_kinds = {
      'github' => N2oFill::Kind::OAUTH_GITHUB_CONNECT,
      'google' => N2oFill::Kind::OAUTH_GOOGLE_CONNECT,
      'linkedin' => N2oFill::Kind::OAUTH_LINKEDIN_CONNECT,
      'twitter' => N2oFill::Kind::OAUTH_TWITTER_CONNECT,
      'facebook' => N2oFill::Kind::OAUTH_FACEBOOK_CONNECT
    }
    oauth_action_bonus = KeyValue[N2oFill::N2O_OAUTH_ACTION_BONUS]

    if n2o_kinds.has_key? provider
      fill_n2o_for_event!(
        kind: n2o_kinds[provider],
        bonus_attribute: provider,
        n2o: oauth_action_bonus
      )
    end
  end

  def fill_n2o_for_chrome_app_installation!
    fill_n2o_for_event!(
      kind: N2oFill::Kind::INSTALL_CHROME_APP,
      bonus_attribute: :chrome_app,
      n2o: KeyValue[N2oFill::N2O_INSTALL_CHROME_APP_BONUS],
      mixpanel_property: :chrome_app_installed
    )
  end

  def fill_n2o_for_twitter_follow!
    fill_n2o_for_event!(
      kind: N2oFill::Kind::TWITTER_FOLLOW,
      bonus_attribute: :twitter_follow,
      n2o: KeyValue[N2oFill::N2O_TWITTER_FOLLOW_BONUS],
      mixpanel_property: :followed_on_twitter
    )
  end

  def fill_n2o_for_tweet!
    fill_n2o_for_event!(
      kind: N2oFill::Kind::TWEET_SENT,
      bonus_attribute: :tweet_sent,
      n2o: KeyValue[N2oFill::N2O_TWEET_SENT_BONUS],
      mixpanel_property: :sent_tweet_on_twitter
    )
  end

  def add_all_public_keys_to_box(box_id)
    box = self.boxes.find(box_id)
    self.public_keys.each { |pk| AddPublicKeyToBoxJob.submit_job(box.id, pk.key) } if box
  end

  def remove_all_public_keys_from_box(box_id)
    box = self.boxes.find(box_id)
    self.public_keys.each { |pk| RemovePublicKeyFromBoxJob.submit_job(box.id, pk.key) } if box
  end

  def self.total_count
    { 'count' => User.count }
  end

  private
  def fill_n2o_for_event!(kind: nil, bonus_attribute: nil, n2o: nil, mixpanel_property: nil)
    unless n2o_fills.where(kind: kind).any?
      bonus.update_attribute(bonus_attribute, Time.now)
      fill_n2o!(n2o, kind) if n2o
      SetMixpanelPropertyJob.submit_job(self.id, mixpanel_property, true) if mixpanel_property
    end
  end

  def give_sign_up_bonus
    sign_up_bonus = KeyValue[N2oFill::N2O_SIGN_UP_BONUS]

    if sign_up_bonus.present?
      self.fill_n2o! sign_up_bonus, N2oFill::Kind::SIGN_UP
    end
  end

  def mark_invite_as_accepted!
    invite = Invite.where(invited_user_id: self.id).first
    invite.accept! if invite
  end

  def create_or_update_invite!
    if referrer_code
      invite = Invite.where(email: email, referral_code: referrer_code).first

      if invite
        invite.update_attribute(:invited_user_id, self.id)
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
      end
    end
  end

  def remove_from_mixpanel
    DeleteMixpanelUserJob.submit_job(self.email)
  end

  def remove_from_mailchimp
    MailchimpJob.submit_job('unsubscribe', Settings.mailchimp_monthly_newsletter_list_id, email: self.email)
    MailchimpJob.submit_job('unsubscribe', Settings.mailchimp_product_announcements_list_id, email: self.email)
  end
end
