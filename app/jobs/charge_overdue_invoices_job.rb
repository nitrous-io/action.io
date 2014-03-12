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
      if invoice.attempted && !invoice.paid
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

