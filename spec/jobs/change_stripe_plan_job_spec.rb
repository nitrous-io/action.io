require 'spec_helper'

describe ChangeStripePlanJob do
  describe '#perform' do
    let!(:stripe_customer) { OpenStruct.new(id: 'id_01',
                                            cards: OpenStruct.new(
                                              data: [ OpenStruct.new(last4: '1234', type: 'Visa', exp_month: 10, exp_year: 2014 ) ]
                                            ))
                           }

    let!(:customer_id) { "cus_0001" }
    let!(:plan_id) { "n2o_250" }

    context 'when a customer for the given id is retrieved' do
      before do
        expect(Stripe::Customer).to receive(:retrieve).with(customer_id) { stripe_customer }
      end

      it 'should update the subscription of the customer to the given plan' do
        expect(stripe_customer).to receive(:update_subscription).with(plan: plan_id)
        ChangeStripePlanJob.new(customer_id, plan_id).perform
      end
    end

    context 'when a customer is not found for the given id' do
      before do
        expect(Stripe::Customer).to receive(:retrieve).with(customer_id) { nil }
      end

      it 'logs a message' do
        expect(Rails.logger).to receive(:info)
        ChangeStripePlanJob.new(customer_id, plan_id).perform
      end
    end
  end

  describe ".submit_job" do
    let!(:customer_id) { "cus_0001" }
    let!(:plan_id) { "n2o_250" }

    it "should submit a delayed job" do
      expect {
        ChangeStripePlanJob.submit_job(customer_id, plan_id)
      }.to change(Delayed::Job, :count).by(1)

      job_handler = Delayed::Job.all[-1].handler

      expect(job_handler).to match /ChangeStripePlanJob.*?customer_id: #{customer_id}/m
      expect(job_handler).to match /ChangeStripePlanJob.*?plan_id: #{plan_id}/m
    end
  end
end


