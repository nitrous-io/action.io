class StripeCustomerProfileJob < Job
  attr_accessor :profile_id, :email, :description, :stripe_token

  def initialize(profile_id, email, description, stripe_token)
    self.profile_id = profile_id
    self.email = email
    self.description = description
    self.stripe_token = stripe_token
  end

  def perform
    billing_profile = BillingProfile.find(self.profile_id)

    if stripe_id = billing_profile.stripe_id
      customer = Stripe::Customer.retrieve(stripe_id)

      if self.stripe_token.present?
        customer.card = self.stripe_token
      end

      customer.email = self.email
      customer.description = self.description

      customer.save
    else
      if self.stripe_token
        customer = Stripe::Customer.create(
          email: self.email,
          description: self.description,
          card: self.stripe_token
        )
      else
        Rails.logger.info "Cannot find a Stripe token or id in billing profile - #{self.profile_id}. Profile wasn't created or updated."
        return
      end
    end

    billing_profile.update_column 'last_four', customer.active_card.last4
    billing_profile.update_column 'card_type', customer.active_card.type
    billing_profile.update_column 'stripe_id', customer.id
  end

  def self.submit_job(profile_id, email, description, stripe_token)
    Delayed::Job.enqueue(self.new(profile_id, email, description, stripe_token))
  end
end

