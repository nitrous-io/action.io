class ChargeOverdueInvoicesJob < Job
  attr_accessor :customer_id

  def initialize(customer_id)
    self.customer_id = customer_id
  end

  def perform
    invoices = Stripe::Invoice.all({
      customer: self.customer_id
    })

    return unless invoices["count"] > 0

    # reverse the list to try the oldest invoices first.
    # (https://stripe.com/docs/api#list_customer_invoices)
    invoices["data"].reverse.each do |invoice|
      # If you look in Stripe dashboard, there are 3 kinds of unpaid invoices.
      # 1. Invoices created by Stripe for a monthly subscription and failed in multiple attempts (will have an attempt count).
      # 2. Invoices created by Stripe after a subscription became delinquent (they are closed by default and attempt count is 0).
      # 3. Invoices created by us to manually charge a user when she upgrades (will have a attempt count of 0)
      # Out of those, we only care about #1 (Invoices created by Stripe for a monthly subscription)
      # Refer to `attempt_count` attribute in https://stripe.com/docs/api#invoice_object
      if !invoice.paid && invoice.attempt_count > 0
        begin
          invoice.pay
        # if there's a card error give up trying
        # rest of the invoices.
        rescue Stripe::CardError => e
          Airbrake.notify(exception) if defined? Airbrake
          return
        end
      end
    end
  end

  def self.submit_job(customer_id)
    Delayed::Job.enqueue self.new(customer_id)
  end
end

