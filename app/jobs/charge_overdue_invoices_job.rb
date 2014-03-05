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

    invoices["data"].each do |invoice|
      if invoice.attempted && !invoice.paid
        invoice.pay
      end
    end
  end

  def self.submit_job(customer_id)
    Delayed::Job.enqueue self.new(customer_id)
  end
end

