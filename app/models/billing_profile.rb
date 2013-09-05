class BillingProfile < ActiveRecord::Base
  attr_accessible :stripe_token, :plan

  belongs_to :user
  has_many :subscriptions
  has_many :receipts

  before_save :create_or_update_stripe_customer
  before_save :change_plan
  after_save  :clear_stripe_token

  attr_accessor :stripe_token, :plan

  validates_presence_of :plan, on: :create

  # reason why we need such a method,
  # rather than having a single subscription association
  # is to maintain user's subscription history for reconcilation purposes.
  def active_subscription
    subscriptions.active.last
  end

  def active
    !!active_subscription
  end

  def expiry
    if exp_month && exp_year
      "#{exp_month}/#{exp_year}"
    end
  end

  def formatted_card_number
    "##############{last_four}"
  end

  def self.handle_event_from_stripe(customer_id, event, opts={})
    billing_profile = BillingProfile.find_by_stripe_id customer_id
    return unless billing_profile

    case event
    when 'subscription_created'
      subscription_plan = SubscriptionPlan.find_by_stripe_id opts[:plan_id]
      subscription = billing_profile.subscriptions.create subscription_plan: subscription_plan
      subscription.activate!
    when 'charge_failed'
      # send the payment failed notice if there's a subscription
      billing_profile.active_subscription.try(:payment_failed!)
    when 'subscription_changed'
      billing_profile.active_subscription.cancel!

      subscription_plan = SubscriptionPlan.find_by_stripe_id opts[:plan_id]
      subscription = billing_profile.subscriptions.create subscription_plan: subscription_plan
      subscription.activate!
    when 'subscription_canceled'
      billing_profile.active_subscription.cancel!
    when 'payment_succeeded'
      billing_profile.receipts.create opts[:receipt_details]
    when 'card_updated'
      # TODO: to implement
    else
      Rails.logger.info "Cannot handle the Stripe event - #{event}"
    end
  end

  private
  def stripe_description
    "#{user.username} #{user.email}"
  end

  def create_or_update_stripe_customer
    begin
      if !new_record? && self.stripe_id
        customer = retrieve_stripe_customer

        if self.stripe_token.present?
          customer.card = self.stripe_token
        end

        customer.email = self.user.email
        customer.description = stripe_description

        customer.save
      else
        if self.stripe_token
          customer = Stripe::Customer.create(
            email: self.user.email,
            description: stripe_description,
            card: self.stripe_token,
            plan: self.plan.stripe_id
          )
        else
          self.errors.add :base, 'invalid request'
          return false
        end
      end

      set_card_properties customer
    rescue Stripe::CardError => e
      body = e.json_body
      err = body[:error]

      if err[:code] == "card_declined"
        error_message = "#{err[:message]} Try contacting your bank directly for assistance."
      else
        error_message = err[:message]
      end

      self.errors.add :base, error_message
      return false
    rescue => e
      # log rest of the errors for now
      Rails.logger.info e
      return false
    end
  end

  def set_card_properties(customer)
    self.last_four = customer.cards.data.first.last4
    self.card_type = customer.cards.data.first.type
    self.exp_month = customer.cards.data.first.exp_month
    self.exp_year  = customer.cards.data.first.exp_year
    self.stripe_id = customer.id
  end

  def clear_stripe_token
    self.stripe_token = nil
  end

  def change_plan
    return if (new_record? || self.plan.nil?)

    # if selected plan results in having less n2o than currently utilised n2o
    # don't allow the plan change
    if selected_plan_has_less_n2o?
      self.errors.add :base, "You're currently using more N2O than what's available in the selected plan. Try selecting a bigger plan."
      return false
    end

    if customer = retrieve_stripe_customer
      customer.update_subscription(plan: self.plan.stripe_id)
    end
  end

  def selected_plan_has_less_n2o?
    current_plan_n2o = active_subscription.subscription_plan.n2o_amount
    new_plan_n2o = self.plan.n2o_amount
    base_n2o = user.max_n2o - current_plan_n2o
    future_n2o = base_n2o + new_plan_n2o

    future_n2o < user.used_n2o
  end

  def retrieve_stripe_customer
    @stripe_customer ||= Stripe::Customer.retrieve(self.stripe_id)
  end
end
