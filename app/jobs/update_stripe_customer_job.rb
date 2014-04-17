class UpdateStripeCustomerJob < Job
  attr_accessor :user_id

  def initialize(user_id)
    self.user_id = user_id
  end

  def perform
    user = User.find(user_id)
    return if !user

    if customer = Stripe::Customer.retrieve(user.stripe_customer_id)
      customer.email = user.email
      customer.save
    else
      Rails.logger.warn "Cannot find a Customer in Stripe for the given id. #{user.stripe_customer_id}"
    end
  end

  def self.submit_job(user_id)
    Delayed::Job.enqueue(self.new(user_id))
  end
end

