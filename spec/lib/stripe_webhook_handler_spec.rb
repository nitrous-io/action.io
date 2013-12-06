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
        Subscription.should_receive(:new).with(user: user, plan: plan) { subscription }
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
        Subscription.should_not_receive(:new).with(user: user, plan: plan) { subscription }
        StripeWebhookHandler.subscription_created(mock_event)
      end
    end

    context 'when a plan cannot be found for the plan id provided by Stripe' do
      before do
        User.stub(:find_by_stripe_customer_id).with('cus_fake') { user }
        Plan.stub(:find_by_stripe_id).with('n2o_1001') { nil }
      end

      it 'should not create a subscription' do
        Subscription.should_not_receive(:new).with(user: user, plan: plan) { subscription }
        StripeWebhookHandler.subscription_created(mock_event)
      end
    end
  end

end
