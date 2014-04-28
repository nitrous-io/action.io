require 'spec_helper'

describe ChargeOverdueInvoicesJob do

  class FakeStripeInvoice
    attr_accessor :closed, :attempt_count, :paid
    attr_reader :saved, :attempted_to_pay

    def initialize(h)
      h.each { |k, v| send("#{k}=", v) }
    end

    def save
      @saved = true
    end

    def pay
      @attempted_to_pay = true
    end

    def saved?
      @saved
    end

    def closed?
      @closed
    end

    def attempted_to_pay?
      @attempted_to_pay
    end
  end

  describe '#perform' do
    context 'when Stripe returns invoices for the user' do
      let(:invoice1) { FakeStripeInvoice.new attempt_count: 4, paid: false, closed: true }
      let(:invoice2) { FakeStripeInvoice.new attempt_count: 2, paid: false, closed: true }
      let(:invoice3) { FakeStripeInvoice.new attempt_count: 4, paid: true,  closed: true }
      let(:invoice4) { FakeStripeInvoice.new attempt_count: 0, paid: false, closed: true }

      let(:invoices) { { "data" => [ invoice1, invoice2, invoice3, invoice4 ], "count" => 4 } }

      before do
        expect(Stripe::Invoice).to receive(:all).with({ customer: "stripe_customer_id" }).and_return invoices
      end

      it 'should try to reopen and pay only the attempted and unpaid invoices' do
        ChargeOverdueInvoicesJob.new("stripe_customer_id").perform

        expect(invoice1).not_to be_closed
        expect(invoice1).to be_saved
        expect(invoice1).to be_attempted_to_paid

        expect(invoice2).not_to be_closed
        expect(invoice2).to be_saved
        expect(invoice2).to be_attempted_to_paid

        expect(invoice3).to be_closed
        expect(invoice3).not_to be_saved
        expect(invoice3).not_to be_attempted_to_paid

        expect(invoice4).to be_closed
        expect(invoice4).not_to be_saved
        expect(invoice4).not_to be_attempted_to_paid
      end

      context 'when a card delcine occurrs when trying to pay an invoice' do
        it 'should not attempt rest of the invoices' do
          expect(invoice2).to receive(:pay).and_raise Stripe::CardError.new('', '', '', nil, nil, { error: { code: '', message: 'stripe error' }})

          ChargeOverdueInvoicesJob.new("stripe_customer_id").perform
          expect(invoice2.attempted_to_pay).to be_falsey
        end
      end
    end

    context 'when Stripe returns no invoices for the user' do
      before do
        empty_response = { "count" => 0, "data" => [] }
        expect(Stripe::Invoice).to receive(:all).with({ customer: "stripe_customer_id" }).and_return(empty_response)
      end

      it 'should return early without calling pay on any invoice' do
        expect_any_instance_of(Stripe::Invoice).to_not receive(:pay)
        ChargeOverdueInvoicesJob.new("stripe_customer_id").perform
      end
    end
  end

  describe ".submit_job" do
    it "should submit a delayed job" do
      expect {
        ChargeOverdueInvoicesJob.submit_job("stripe_customer_id")
      }.to change(Delayed::Job, :count).by(1)

      job_handler = Delayed::Job.all[-1].handler

      expect(job_handler).to match /ChargeOverdueInvoicesJob.*?customer_id: stripe_customer_id/m
    end
  end
end
