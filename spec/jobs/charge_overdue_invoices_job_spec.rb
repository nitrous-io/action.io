require 'spec_helper'

describe ChargeOverdueInvoicesJob do
  describe '#perform' do

    context 'when Stripe returns invoices for the user' do
      let(:invoice1) { double "Stripe::Invoice", attempted: true, paid: false }
      let(:invoice2) { double "Stripe::Invoice", attempted: true, paid: false }
      let(:invoice3) { double "Stripe::Invoice", attempted: true, paid: true }
      let(:invoice4) { double "Stripe::Invoice", attempted: false, paid: false }

      let(:invoices) { { "data" => [ invoice1, invoice2, invoice3, invoice4 ], "count" => 4 } }

      before do
        expect(Stripe::Invoice).to receive(:all).with({ customer: "stripe_customer_id" }).and_return invoices
      end

      it 'should try to pay only the attempted and unpaid invoices' do
        expect(invoice1).to receive(:pay)
        expect(invoice2).to receive(:pay)
        expect(invoice3).to_not receive(:pay)
        expect(invoice4).to_not receive(:pay)

        ChargeOverdueInvoicesJob.new("stripe_customer_id").perform
      end

      context 'when a card delcine occurrs when trying to pay an invoice' do
        it 'should not attempt rest of the invoices' do
          expect(invoice2).to receive(:pay).and_raise Stripe::CardError.new('', '', '', nil, nil, { error: { code: '', message: 'stripe error' }})
          expect(invoice1).to_not receive(:pay)

          ChargeOverdueInvoicesJob.new("stripe_customer_id").perform
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
