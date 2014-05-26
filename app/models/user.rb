class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :recoverable
  # :validatable,
  #
  devise :database_authenticatable, :omniauthable, :registerable,
         :rememberable, :trackable, :token_authenticatable,
         :recoverable, :confirmable

  acts_as_paranoid

  attr_accessible :username, :email, :full_name, :password,
    :password_confirmation, :remember_me, :login, :referrer_code,
    :user_profile_attributes, :user_settings_attributes, :coupon_code,
    :plan_group
  attr_accessor   :login, :validate_confirmation, :referrer_code

  has_many :authentications, dependent: :destroy
  has_many :box_users,       dependent: :destroy
  has_many :boxes,           through:   :box_users
  has_many :boxhosts,        dependent: :nullify, foreign_key: 'owner_id'
  has_many :snapshots,       dependent: :nullify
  has_many :owned_boxes,     dependent: :nullify, class_name: 'Box', foreign_key: 'owner_id'
  has_many :public_keys,     dependent: :destroy
  has_many :oauth_applications, class_name: 'Doorkeeper::Application', as: :owner, dependent: :destroy
  has_many :owned_invites,   dependent: :nullify, class_name: 'Invite', foreign_key: 'inviting_user_id'
  has_many :n2o_fills,       dependent: :destroy
  has_many :n2o_allocations, dependent: :destroy
  has_many :user_events      # no dependent destroy since we want retain events for debugging
  has_one  :bonus,           dependent: :destroy
  has_one  :user_profile,    dependent: :destroy
  has_one  :user_settings,   dependent: :destroy
  has_one  :billing_profile, dependent: :destroy
  has_one  :subscription,    dependent: :destroy

  belongs_to  :plan_group

  accepts_nested_attributes_for :user_profile, :user_settings

  validates :username,  uniqueness: { scope: :deleted_at }, allow_nil: true
  validates :username,  presence: true, length: { in: (2..20) }, if: :missing_authentications?
  validates_format_of :username, with: /\A[a-z0-9][a-z0-9\-]*\z/i,
    message: "may only contain alphanumeric characters or dashes and cannot begin with a dash",
    if: :missing_authentications?
  validates_exclusion_of :username, in: USERNAME_BLACKLIST
  validates :email,     presence: true, uniqueness: { scope: :deleted_at }
  validates :full_name, length: { in: (0..40), allow_nil: true }

  # :validatable does not scope for deleted_at and cannot be used
  # The validations it adds (as of 3.0.4) are below
  validates :password, presence: { if: :password_required? }, confirmation: { if: :password_required? }, length: { within: Devise.password_length, allow_blank: true }
  validates :email, format: { with: Devise.email_regexp, allow_blank: true, if: :email_changed? }

  validates_with  ::EmailValidator

  before_validation :set_referral_code!

  before_save     :ensure_authentication_token
  before_save     :set_active_coupon_code
  before_create   :set_referral_code!

  after_create    :create_or_update_invite!

  before_destroy  :reset_password
  before_destroy  :remove_from_mixpanel
  before_destroy  :remove_from_mailchimp

  scope :banned,    -> { where("banned_at IS NOT NULL") }
  scope :delinquent,  -> { where("delinquent_at IS NOT NULL") }
  scope :with_login, ->(login) { where('lower(username) = :value OR lower(email) = :value', {value: login.downcase}) }

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

    UpdateStripeCustomerJob.submit_job(self.id) if self.stripe_customer_id
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

  def user_settings_with_create
    User.transaction(requires_new: true) do
      user_settings = user_settings_without_create
      user_settings.present? ? user_settings : create_user_settings
    end
  end
  alias_method_chain :user_settings, :create

  def billing_profile_with_create
    User.transaction(requires_new: true) do
      billing_profile = billing_profile_without_create
      billing_profile.present? ? billing_profile : create_billing_profile
    end
  end
  alias_method_chain :billing_profile, :create

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

  def repositories
    visible_boxes.map { |b| b.repositories }.flatten(1)
  end

  def able_to_login?
    username.present?
  end

  def active_for_authentication?
    return false if banned_at.present?
    in_private_beta? ? true : super
  end

  def active_plan
    return unless subscription && subscription.active?
    @active_plan ||= subscription.plan
  end

  def subscription_pending
    return false unless subscription
    subscription.pending?
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
      with_login(login).where(conditions).first
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

  def set_active_coupon_code
    return unless self.coupon_code_changed?

    self.coupon_code = self.get_active_coupon_code
  end

  def eligible_for_coupon?
    self.active_plan.blank?
  end

  def aws_activate_plans_enabled # should be ?-suffixed but that breaks serializer include_* method
    PlanGroup::AWS_ACTIVATE_TERMS[self.plan_group.try(:name)].present?
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

  def fill_n2o_for_business_survey!
    fill_n2o_for_event!(
      kind: N2oFill::Kind::BUSINESS_SURVEY,
      bonus_attribute: :business_survey,
      n2o: KeyValue[N2oFill::N2O_BUSINESS_SURVEY_BONUS],
      mixpanel_property: :business_survey_completed
    )
  end

  def fill_n2o_for_user_survey_1!
    fill_n2o_for_event!(
      kind: N2oFill::Kind::USER_SURVEY_1,
      bonus_attribute: :user_survey_1,
      n2o: KeyValue[N2oFill::N2O_USER_SURVEY_1_BONUS],
      mixpanel_property: :user_survey_1_completed
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

  # Sends a request to Stripe to create a subscription.
  def subscribe(plan, stripe_token)
    if subscription && subscription.active?
      errors.add :base, 'You already have an active subscription'
      return false
    end

    unless stripe_token && plan
      errors.add :base, 'invalid request'
      return false
    end

    begin
      if self.stripe_customer_id.present?
        customer = Stripe::Customer.retrieve(self.stripe_customer_id)
        customer.email = self.email
        customer.description = "#{self.email} #{self.username}"
        customer.card = stripe_token
        customer.plan = plan.stripe_id

        # Only set the coupon if the user has an active coupon.
        # Cannot pass a nil value, as Stripe converts it to an empty string.
        # (https://github.com/stripe/stripe-ruby/issues/84)
        if coupon_code = self.get_active_coupon_code
          customer.coupon = coupon_code
        end

        customer.save
        ChargeOverdueInvoicesJob.submit_job(self.stripe_customer_id)
      else
        customer = Stripe::Customer.create(
          email: self.email,
          description: "#{self.email} #{self.username}",
          card: stripe_token,
          plan: plan.stripe_id,
          coupon: self.get_active_coupon_code
        )
      end
    rescue Stripe::CardError => e
      body = e.json_body
      err = body[:error]

      if err[:code] == "card_declined"
        error_message = "#{err[:message]} Try contacting your bank directly for assistance."
      else
        error_message = err[:message]
      end

      errors.add :base, error_message
      return false
    rescue Stripe::APIConnectionError => e
      errors.add :base, 'Cannot process your request at this time'
      Airbrake.notify_or_ignore(e) if defined? Airbrake
      return false
    rescue Stripe::StripeError => e
      errors.add :base, 'Cannot process your request at this time'
      Airbrake.notify_or_ignore(e) if defined? Airbrake
      return false
    end

    save_stripe_card_to_billing_profile(customer)
    update_attribute 'stripe_customer_id', customer.id
    PushBillingProfileUpdatedJob.submit_job(id)
  end

  # Creates and activates the subscription after webhook is called by Stripe.
  def apply_subscription(plan)
    if self.subscription
      # Return early if the subscription is already active.
      return if self.subscription.active?

      self.subscription.plan = plan
      self.subscription.created_at = Time.now
    else
      self.build_subscription plan: plan
    end

    self.subscription.activate!
  end

  def get_stripe_customer
    begin
      customer = Stripe::Customer.retrieve(stripe_customer_id)
    rescue Stripe::APIConnectionError => e
      errors.add :base, 'Cannot process your request at this time'
      Airbrake.notify_or_ignore(e) if defined? Airbrake
      return nil
    rescue Stripe::StripeError => e
      errors.add :base, 'Cannot process your request at this time'
      Airbrake.notify_or_ignore(e) if defined? Airbrake
      return nil
    end

    if customer.blank?
      errors.add :base, 'It looks like you do not have a subscription. If this is incorrect, please contact support@nitrous.io.'
    end

    customer
  end

  def change_plan(plan)
    return false if plan.nil? || subscription.plan == plan

    if plan.is_price_downgrade_from subscription.plan
      downgrade_plan plan
    else
      upgrade_plan plan
    end
  end

  def downgrade_plan(plan)
    unless can_downgrade_to_plan?(plan)
      errors.add :base, 'You need to terminate boxes to free up N2O before downgrading from current plan. Please contact support@nitrous.io with any questions.'
      return false
    end
    change_plan_in_stripe(plan)
  end

  def upgrade_plan(plan)
    change_plan_in_stripe(plan)

    # store the pending plan in subscription
    subscription.update_column :pending_plan_id, plan.id
  end

  # Sends a request to Stripe to change subscription plan.
  def change_plan_in_stripe(plan, prorate: true)
    customer = get_stripe_customer
    return false if customer.blank?

    customer.update_subscription(plan: plan.stripe_id, prorate: prorate)
  end

  # Changes the subscription plan after receiving webhook from Stripe.
  def apply_change_plan(new_plan)
    return false unless subscription.active?
    return false if new_plan.id == subscription.plan_id

    # If it is an upgrade, we need to charge the user before changing the plan.
    # Hence we store it as a pending plan,
    # and charge for it before actually applying the plan change.
    # This doesn't matter for downgrades, so we change it directly.
    if subscription.pending_plan && (subscription.pending_plan == new_plan)
      charge_for_pending_plan
    else
      subscription.change_plan!(new_plan)
    end
  end

  def charge_for_pending_plan
    # return if there's no pending upgrade
    return false if subscription.pending_plan_id.blank?

    # create an invoice with pending items
    invoice = Stripe::Invoice.create customer: self.stripe_customer_id

    # store the pending invoice id
    subscription.update_column :stripe_invoice_id, invoice.id

    # pay the invoice
    invoice.pay

    # Once we attempt to charge the user,
    # we wait for the charge status to notified via webhook.
    # Webhook will call Subscription#charge_succeeded and Subscription#charge_failed methods accordingly.
    # Refer those methods for the continuation of the upgrade workflow.
  rescue Stripe::CardError => e
    errors.add :base, 'Card Declined'
    Airbrake.notify_or_ignore(e) if defined? Airbrake
    return false
  rescue Stripe::APIConnectionError => e
    errors.add :base, 'Cannot process your request at this time'
    Airbrake.notify_or_ignore(e) if defined? Airbrake
    return false
  rescue Stripe::StripeError => e
    errors.add :base, 'Cannot process your request at this time'
    Airbrake.notify_or_ignore(e) if defined? Airbrake
    return false
  end

  # params
  # force (boolean) - proceed even when user is not allowed to cancel subscription due to resource usage
  def cancel_subscription(force: false)
    if subscription.pending? || subscription.canceled?
      errors.add :base, 'You do not have an active subscription. If this is incorrect, please contact support@nitrous.io.'
      return false
    end

    if !force && !can_cancel_plan?
      errors.add :base, 'You need to terminate boxes to free up N2O before downgrading from current plan. Please contact support@nitrous.io with any questions.'
      return false
    end

    customer = get_stripe_customer
    return false if customer.blank?

    customer.cancel_subscription

    ActiveRecord::Base.transaction do
      subscription.cancel!
      undelinquent! # delinquency doesn't matter anymore if user cancels the subscription
    end

    DowngradeBoxesJob.submit_job(id)
    true
  end

  # The new plan's n2o fill should be more than or equal to user's currently
  # utilized n2o.
  def can_downgrade_to_plan?(new_plan=nil)
    current_plan_n2o = subscription.plan.n2o_amount
    new_plan_n2o = new_plan ? new_plan.n2o_amount : 0
    return true if new_plan_n2o >= current_plan_n2o

    future_n2o = max_n2o - current_plan_n2o + new_plan_n2o

    future_n2o >= used_n2o
  end

  def can_cancel_plan?
    can_downgrade_to_plan?(nil) # Explicit nil here reads better.
  end

  def box_snapshots_allowed
    plan = self.active_plan
    plan.present? && plan.has_feature?(Plan::FEATURE_BOX_SNAPSHOTS)
  end

  def change_card(stripe_token)
    return false unless stripe_token.present?

    begin
      customer = Stripe::Customer.retrieve(stripe_customer_id)
      customer.card = stripe_token
      customer.save

    rescue Stripe::CardError => e
      body = e.json_body
      err = body[:error]

      if err[:code] == "card_declined"
        error_message = "#{err[:message]} Try contacting your bank directly for assistance."
      else
        error_message = err[:message]
      end

      errors.add :base, error_message
      return false
    rescue Stripe::APIConnectionError => e
      errors.add :base, 'Cannot process your request at this time'
      Airbrake.notify_or_ignore(e) if defined? Airbrake
      return false
    rescue Stripe::StripeError => e
      errors.add :base, 'Cannot process your request at this time'
      Airbrake.notify_or_ignore(e) if defined? Airbrake
      return false
    end

    save_stripe_card_to_billing_profile(customer)
    SubscriptionMailer.delay.credit_card_changed_alert(id)
    PushBillingProfileUpdatedJob.submit_job(id)
    ChargeOverdueInvoicesJob.submit_job(self.stripe_customer_id)
  end

  def ban!
    self.password = SecureRandom.base64(15)
    self.banned_at = Time.now
    clear_reset_password_token
    n2o_fills.destroy_all
    save validate: false
    owned_boxes.running.each { |b| b.transition_triggered(:enqueue_stop!, 'admin') }
    self.cancel_subscription(force: true) if self.active_plan
    user_events.create! event: UserEvent::BANNED
    SetMixpanelPropertyJob.submit_job self.id, :banned, true
  end

  def delinquent!
    update_column :delinquent_at, Time.now
    owned_boxes.running.each { |b| b.transition_triggered(:enqueue_stop!, 'system') }
    push_delinquent_at_updated_message
  end

  def undelinquent!
    if self.delinquent?
      update_column :delinquent_at, nil
      push_delinquent_at_updated_message
    end
  end

  def delinquent?
    !!self.delinquent_at
  end

  def reset_password!(new_password, new_password_confirmation)
    super unless banned_at.present?
  end

  def push_delinquent_at_updated_message
    Shover.publish self.id, 'aio:delinquent_at_updated', { user: { delinquent_at: self.delinquent_at } }
  end

  def self.total_count
    { 'count' => User.count }
  end

  protected
  def generate_reset_password_token
    super unless banned_at.present?
  end

  def save_stripe_card_to_billing_profile(customer)
    self.billing_profile.last_four = customer.cards.data.first.last4
    self.billing_profile.card_type = customer.cards.data.first.type
    self.billing_profile.exp_month = customer.cards.data.first.exp_month
    self.billing_profile.exp_year = customer.cards.data.first.exp_year
    self.billing_profile.save
  end

  def get_active_coupon_code
    return nil unless self.coupon_code.present?

    if coupon = Coupon.active.find_by_code(self.coupon_code.downcase)
      coupon.code
    end
  end

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

  def reset_password # before_destroy
    self.password = self.password_confirmation = "deleted#{SecureRandom.hex[0..5]}"
  end

  def remove_from_mixpanel # before_destroy
    DeleteMixpanelUserJob.submit_job(self.email)
  end

  def remove_from_mailchimp # before_destroy
    MailchimpJob.submit_job('unsubscribe', Settings.mailchimp_monthly_newsletter_list_id, email: self.email)
    MailchimpJob.submit_job('unsubscribe', Settings.mailchimp_product_announcements_list_id, email: self.email)
  end

  # from Devise https://github.com/plataformatec/devise/blob/v3.0.4/lib/devise/models/validatable.rb
  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end
end
