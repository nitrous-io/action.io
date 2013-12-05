require 'spec_helper'

describe StripeWebhookHandler do
  describe '.subscription_created' do
    let!(:mock_event) { double }

    before do
      mock_event.stub_chain('data.object.customer') { 'cus_fake' }
      mock_event.stub_chain('data.object.plan.id') { 'n2o_1001' }
    end

    context 'when a user can be found with the stripe customer id' do
      let!(:user) { create :user }
      let!(:subscription) { double }

      before do
        User.stub(:find_by_stripe_customer_id).with('cus_fake') { user }
      end

      it 'should instantiate a subscription for the user' do
        subscription.stub(:activate!)

        Subscription.should_receive(:new).with(user: user) { subscription }
        StripeWebhookHandler.subscription_created(mock_event)
      end

      it 'should activate the new subscription' do
        subscription.should_receive(:activate!)
        Subscription.stub(:new) { subscription }

        StripeWebhookHandler.subscription_created(mock_event)
      end
    end

    context 'when a user cannot be found with the stripe customer id' do
      before do
        User.stub(:find_by_stripe_customer_id).with('cus_fake') { nil }
      end

      it 'should not instantiate a subscription' do
        Subscription.should_not_receive(:new)
        StripeWebhookHandler.subscription_created(mock_event)
      end
    end
  end

end
