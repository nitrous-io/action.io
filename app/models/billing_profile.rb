class BillingProfile < ActiveRecord::Base
  attr_accessible :stripe_token
  belongs_to :user
  after_save :update_stripe

  attr_accessor :stripe_token

  protected
  def stripe_description
    "#{user.username} #{user.email}"
  end

  def update_stripe
    StripeCustomerProfileJob.submit_job(id, user.email, stripe_description, stripe_token)

    # clear stripe token
    self.stripe_token = nil
  end
end
