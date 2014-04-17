require 'spec_helper'

describe UpdateStripeCustomerJob do
  describe '#perform' do
    let!(:stripe_customer) { double "Stripe::Customer" }

    let!(:user) { create :user, stripe_customer_id: "cus_0001" }

    context 'when a customer for the given id is retrieved' do
      before do
        expect(Stripe::Customer).to receive(:retrieve).with("cus_0001") { stripe_customer }
      end

      it 'should update the email of the customer' do
        expect(stripe_customer).to receive(:email=).with(user.email)
        expect(stripe_customer).to receive(:save)
        UpdateStripeCustomerJob.new(user.id).perform
      end
    end

    context 'when a customer is not found for the given id' do
      before do
        expect(Stripe::Customer).to receive(:retrieve).with("cus_0001") { nil }
      end

      it 'logs a message' do
        expect(Rails.logger).to receive(:warn)
        UpdateStripeCustomerJob.new(user.id).perform
      end
    end
  end

  describe ".submit_job" do
    let!(:user) { create :user }

    it "should submit a delayed job" do
      expect {
        UpdateStripeCustomerJob.submit_job(user.id)
      }.to change(Delayed::Job, :count).by(1)

      job_handler = Delayed::Job.all[-1].handler

      expect(job_handler).to match /UpdateStripeCustomerJob.*?user_id: #{user.id}/m
    end
  end
end
