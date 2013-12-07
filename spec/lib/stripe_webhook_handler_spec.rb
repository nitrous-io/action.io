require 'spec_helper'

describe StripeWebhookHandler do
  describe '.subscription_created' do
    let!(:mock_event) { double }
    let!(:user) { create :user }
    let!(:plan) { create :plan }
    let!(:subscription) { double }

    before do
      mock_event.stub_chain('data.object.customer') { 'cus_fake' }
      mock_event.stub_chain('data.object.plan.id') { 'n2o_1001' }
    end

    context 'when there is matching a user and a plan for the ids provided by Stripe' do
      before do
        User.stub(:find_by_stripe_customer_id).with('cus_fake') { user }
        Plan.stub(:find_by_stripe_id).with('n2o_1001') { plan }
      end

      it 'should create a new active subscription with the user and the plan' do
        user.should_receive(:create_subscription).with(plan: plan) { subscription }
        subscription.should_receive(:activate!)

        StripeWebhookHandler.subscription_created(mock_event)
      end
    end

    context 'when a user cannot be found for the customer id provided by Stripe' do
      before do
        User.stub(:find_by_stripe_customer_id).with('cus_fake') { nil }
        Plan.stub(:find_by_stripe_id).with('n2o_1001') { plan }
      end

      it 'should not create a subscription' do
        user.should_not_receive(:create_subscription).with(plan: plan)
        StripeWebhookHandler.subscription_created(mock_event)
      end
    end

    context 'when a plan cannot be found for the plan id provided by Stripe' do
      before do
        User.stub(:find_by_stripe_customer_id).with('cus_fake') { user }
        Plan.stub(:find_by_stripe_id).with('n2o_1001') { nil }
      end

      it 'should not create a subscription' do
        user.should_not_receive(:create_subscription).with(plan: plan)
        StripeWebhookHandler.subscription_created(mock_event)
      end
    end
  end

  describe '.payment_succeeded' do
    let!(:mock_event) { double }
    let!(:user) { create :user }
    let!(:billing_profile) { create :billing_profile, user: user }

    before do
      mock_event.stub_chain('data.object.customer') { 'cus_fake' }
      mock_event.stub_chain('data.object.period_start') { Time.new(2013, 1, 1).to_i }
      mock_event.stub_chain('data.object.period_end') { Time.new(2013, 2, 1).to_i }
      mock_event.stub_chain('data.object.lines.data') { %w(wall of text wall of text wall of text) }
      mock_event.stub_chain('data.object.subtotal') { 1999 }
      mock_event.stub_chain('data.object.total') { 2000 }
    end

    context 'when there is matching a user for the id provided by Stripe' do
      before do
        User.stub(:find_by_stripe_customer_id).with('cus_fake') { user }
      end

      it 'should create a receipt for the billing profile of the user' do
        expect {
          StripeWebhookHandler.payment_succeeded(mock_event)
        }.to change { Receipt.count }.by(1)

        receipt = Receipt.last
        expect(receipt.period_start).to eq(Time.new(2013, 1, 1))
        expect(receipt.period_end).to eq(Time.new(2013, 2, 1))
        expect(receipt.lines).to eq(%w(wall of text wall of text wall of text))
        expect(receipt.subtotal).to eq(1999)
        expect(receipt.total).to eq(2000)
      end

      it 'should start a job to track the revenue we made (as a currency value) indicated in event from Stripe' do
        TrackMixpanelRevenueJob.should_receive(:submit_job).with(user.id, 20.0)
        StripeWebhookHandler.payment_succeeded(mock_event)
      end
    end

    context 'when a user cannot be found for the customer id provided by Stripe' do
      before do
        User.stub(:find_by_stripe_customer_id).with('cus_fake') { nil }
      end

      it 'should not create a new receipt' do
        expect {
          StripeWebhookHandler.payment_succeeded(mock_event)
        }.not_to change { Receipt.count }
      end
    end

  end
end
