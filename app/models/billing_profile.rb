class BillingProfile < ActiveRecord::Base
  attr_accessible :stripe_token, :plan

  belongs_to :user
  has_many :subscriptions

  after_save :update_stripe

  attr_accessor :stripe_token, :plan

  def active_subscription
    subscriptions.active.last
  end

  def self.handle_event_from_stripe(customer_id, event, opts={})
    billing_profile = BillingProfile.find_by_stripe_id customer_id
    return unless billing_profile

    case event
    when 'charge_failed'
      billing_profile.active_subscription.payment_failed!
    else
      Rails.logger.info "Cannot handle the Stripe event - #{event}"
    end
  end

  protected
  def stripe_description
    "#{user.username} #{user.email}"
  end

  def update_stripe
    CreateOrUpdateStripeCustomerJob.submit_job(id, user.email, stripe_description, stripe_token, plan.try(:id))

    # clear stripe token
    self.stripe_token = nil
  end
end
