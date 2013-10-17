class ChangeStripePlanJob < Job
  attr_accessor :customer_id, :plan_id

  def initialize(customer_id, plan_id)
    self.customer_id = customer_id
    self.plan_id = plan_id
  end

  def perform
    if customer = Stripe::Customer.retrieve(self.customer_id)
      customer.update_subscription(plan: self.plan_id)
    else
      Rails.logger.info "Cannot find a Customer in Stripe for the given id. #{self.customer_id}"
      return
    end
  end

  def self.submit_job(customer_id, plan_id)
    Delayed::Job.enqueue(self.new(customer_id, plan_id))
  end
end

