class BillingProfile < ActiveRecord::Base
  attr_accessible :stripe_token, :plan

  belongs_to :user
  has_many :subscriptions

  after_save :update_stripe

  attr_accessor :stripe_token, :plan

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
