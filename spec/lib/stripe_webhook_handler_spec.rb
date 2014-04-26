require 'spec_helper'

describe StripeWebhookHandler do
  describe '.subscription_created' do
    let!(:mock_event) { double }
    let!(:user) { create :user }
    let!(:plan) { create :plan }
    let!(:subscription) { double }

    before do
      mock_event.stub('id') { 'stripe_event_id' }
      mock_event.stub('created') { 1394531936 }
      mock_event.stub_chain('data.object.customer') { 'cus_fake' }
      mock_event.stub_chain('data.object.plan.id') { 'n2o_1001' }
      mock_event.stub_chain('data.object.start') { 1394531936 }
    end

    context 'when there is a matching user and plan for the ids provided by Stripe' do
      before do
        User.stub(:find_by_stripe_customer_id).with('cus_fake') { user }
        Plan.stub(:find_by_stripe_id).with('n2o_1001') { plan }
      end

      it 'should create a new active subscription with the user and the plan' do
        expect(user).to receive(:apply_subscription).with(plan) { subscription }

        StripeWebhookHandler.subscription_created(mock_event)
      end

      it 'should create a new revenue event' do
        StripeWebhookHandler.subscription_created(mock_event)

        revenue_event = RevenueEvent.last
        expect(revenue_event.event).to eq RevenueEvent::SUBSCRIBED
        expect(revenue_event.amount).to eq plan.price_in_cents
        expect(revenue_event.created_at).to eq Time.at(1394531936)
        expect(revenue_event.stripe_id).to eq 'stripe_event_id'
        expect(revenue_event.subscription_started_at).to eq Time.at(1394531936)
      end
    end

    context 'when a user cannot be found for the customer id provided by Stripe' do
      before do
        User.stub(:find_by_stripe_customer_id).with('cus_fake') { nil }
        Plan.stub(:find_by_stripe_id).with('n2o_1001') { plan }
      end

      it 'should not create a subscription' do
        expect(user).not_to receive(:apply_subscription).with(plan)
        StripeWebhookHandler.subscription_created(mock_event)
      end
    end

    context 'when a plan cannot be found for the plan id provided by Stripe' do
      before do
        User.stub(:find_by_stripe_customer_id).with('cus_fake') { user }
        Plan.stub(:find_by_stripe_id).with('n2o_1001') { nil }
      end

      it 'should not create a subscription' do
        expect(user).not_to receive(:apply_subscription).with(plan)
        StripeWebhookHandler.subscription_created(mock_event)
      end
    end

  end

  describe '.subscription_updated' do
    let!(:mock_event) { double }
    let!(:user) { create :user }
    let!(:plan) { create :plan, price: 19.99 }

    let!(:cheaper_plan) { create :plan, price: 9.99 }
    let!(:expensive_plan) { create :plan, price: 39.99 }

    before do
      mock_event.stub('id') { 'stripe_event_id' }
      mock_event.stub('created') { 1394531936 }
      mock_event.stub_chain('data.object.customer') { 'cus_fake' }
      mock_event.stub_chain('data.object.plan.id') { 'n2o_1001' }
      mock_event.stub_chain('data.previous_attributes.plan.id') { 'n2o_1002' }
      mock_event.stub_chain('data.object.start') { 1394531936 }
    end

    context 'when subscription is a price downgrade' do
      before do
        allow(Plan).to receive(:find_by_stripe_id).with('n2o_1001') { plan }
        allow(Plan).to receive(:find_by_stripe_id).with('n2o_1002') { expensive_plan }
      end

      it 'should create a downgrade revenue event' do
        StripeWebhookHandler.subscription_updated(mock_event)

        revenue_event = RevenueEvent.last
        expect(revenue_event.event).to eq RevenueEvent::DOWNGRADED
        expect(revenue_event.amount).to eq (expensive_plan.price_in_cents - plan.price_in_cents)
        expect(revenue_event.created_at).to eq Time.at(1394531936)
        expect(revenue_event.stripe_id).to eq 'stripe_event_id'
        expect(revenue_event.subscription_started_at).to eq Time.at(1394531936)
      end
    end

    context 'when subscription is a price upgrade' do
      before do
        allow(Plan).to receive(:find_by_stripe_id).with('n2o_1001') { plan }
        allow(Plan).to receive(:find_by_stripe_id).with('n2o_1002') { cheaper_plan }
      end

      it 'should create a upgrade revenue event' do
        StripeWebhookHandler.subscription_updated(mock_event)

        revenue_event = RevenueEvent.last
        expect(revenue_event.event).to eq RevenueEvent::UPGRADED
        expect(revenue_event.amount).to eq (plan.price_in_cents - cheaper_plan.price_in_cents)
        expect(revenue_event.created_at).to eq Time.at(1394531936)
        expect(revenue_event.stripe_id).to eq 'stripe_event_id'
        expect(revenue_event.subscription_started_at).to eq Time.at(1394531936)
      end
    end

    context 'when there is a matching user and plan for the ids provided by Stripe' do
      before do
        User.stub(:find_by_stripe_customer_id).with('cus_fake') { user }

        allow(Plan).to receive(:find_by_stripe_id).with('n2o_1001') { plan }
        allow(Plan).to receive(:find_by_stripe_id).with('n2o_1002') { plan }
      end

      it 'should call apply_plan_change on user with the new plan' do
        expect(user).to receive(:apply_plan_change).with(plan)
        StripeWebhookHandler.subscription_updated(mock_event)
      end
    end

    context 'when a user cannot be found for the customer id provided by Stripe' do
      before do
        User.stub(:find_by_stripe_customer_id).with('cus_fake') { nil }

        allow(Plan).to receive(:find_by_stripe_id).with('n2o_1001') { plan }
        allow(Plan).to receive(:find_by_stripe_id).with('n2o_1002') { cheaper_plan }
      end

      it 'should not call apply_plan_change on user with the new plan' do
        expect(user).not_to receive(:apply_plan_change).with(plan)
        StripeWebhookHandler.subscription_updated(mock_event)
      end
    end

    context 'when a plan cannot be found for the new plan id provided by Stripe' do
      before do
        User.stub(:find_by_stripe_customer_id).with('cus_fake') { user }
        Plan.stub(:find_by_stripe_id).with('n2o_1001') { nil }
      end

      it 'should not call apply_plan_change on user with the new plan' do
        expect(user).not_to receive(:apply_plan_change).with(plan)
        StripeWebhookHandler.subscription_updated(mock_event)
      end
    end
  end

  describe '.subscription_deleted' do
    let!(:mock_event) { double }
    let!(:plan) { create :plan, price: 19.99 }

    before do
      mock_event.stub('id') { 'stripe_event_id' }
      mock_event.stub('created') { 1394531936 }
      mock_event.stub_chain('data.object.plan.id') { 'n2o_1001' }
      mock_event.stub_chain('data.object.start') { 1394531936 }
      mock_event.stub_chain('data.object.customer') { 'cus_fake' }

      allow(Plan).to receive(:find_by_stripe_id).with('n2o_1001') { plan }
    end

    it 'should create a canceled revenue event' do
      StripeWebhookHandler.subscription_deleted(mock_event)

      revenue_event = RevenueEvent.last
      expect(revenue_event.event).to eq RevenueEvent::CANCELED
      expect(revenue_event.amount).to eq plan.price_in_cents
      expect(revenue_event.created_at).to eq Time.at(1394531936)
      expect(revenue_event.stripe_id).to eq 'stripe_event_id'
      expect(revenue_event.subscription_started_at).to eq Time.at(1394531936)
    end

    context 'when a plan cannot be found for the new plan id provided by Stripe' do
      before do
        allow(Plan).to receive(:find_by_stripe_id).with('n2o_1001') { nil }
      end

      it 'should not create a revenue event' do
        expect {
          StripeWebhookHandler.subscription_deleted(mock_event)
        }.to_not change { RevenueEvent.count }
      end
    end
  end

  describe '.payment_succeeded' do
    let!(:mock_event) { double }
    let!(:user) { create :user }
    let!(:billing_profile) { create :billing_profile, user: user }
    let!(:subscription) { create :subscription, user: user }

    before do
      mock_event.stub('id') { 'stripe_event_id' }
      mock_event.stub('created') { 1394531936 }
      mock_event.stub_chain('data.object.customer') { 'cus_fake' }
      mock_event.stub_chain('data.object.id') { 'inv_001' }
      mock_event.stub_chain('data.object.period_start') { Time.new(2013, 1, 1).to_i }
      mock_event.stub_chain('data.object.period_end') { Time.new(2013, 2, 1).to_i }
      mock_event.stub_chain('data.object.lines.data') { %w(wall of text wall of text wall of text) }
      mock_event.stub_chain('data.object.subtotal') { 1999 }
      mock_event.stub_chain('data.object.total') { 2000 }
    end

    context 'when there is a matching user for the id provided by Stripe' do
      before do
        User.stub(:find_by_stripe_customer_id).with('cus_fake') { user }
        user.stub(:process_pending_upgrade)
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

      it "should call charge_succeeded on user's subscription" do
        expect(user.subscription).to receive(:charge_succeeded)
        StripeWebhookHandler.payment_succeeded(mock_event)
      end

      it 'should start a job to track the revenue we made (as a currency value) indicated in event from Stripe' do
        expect(TrackMixpanelRevenueJob).to receive(:submit_job).with(user.id, 20.0)
        StripeWebhookHandler.payment_succeeded(mock_event)
      end

      it 'should call process pending upgrade on user with the invoice id' do
        expect(user).to receive(:process_pending_upgrade).with('inv_001')
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

  describe '.invoice_created' do
    let!(:mock_event) { double }

    before do
      mock_event.stub('id') { 'stripe_event_id' }
      mock_event.stub('created') { 1394531936 }
      mock_event.stub_chain('data.object.total') { 2000 }
    end

    it 'should create a charged revenue event' do
      StripeWebhookHandler.invoice_created(mock_event)

      revenue_event = RevenueEvent.last
      expect(revenue_event.event).to eq RevenueEvent::BILLED
      expect(revenue_event.amount).to eq 2000
      expect(revenue_event.created_at).to eq Time.at(1394531936)
      expect(revenue_event.stripe_id).to eq 'stripe_event_id'
    end
  end

  describe '.charge_succeeded' do
    let!(:mock_event) { double }

    before do
      mock_event.stub('id') { 'stripe_event_id' }
      mock_event.stub('created') { 1394531936 }
      mock_event.stub_chain('data.object.amount') { 2000 }
    end

    it 'should create a charged revenue event' do
      StripeWebhookHandler.charge_succeeded(mock_event)

      revenue_event = RevenueEvent.last
      expect(revenue_event.event).to eq RevenueEvent::CHARGED
      expect(revenue_event.amount).to eq 2000
      expect(revenue_event.created_at).to eq Time.at(1394531936)
      expect(revenue_event.stripe_id).to eq 'stripe_event_id'
    end
  end

  describe '.charge_refunded' do
    let!(:mock_event) { double }

    before do
      mock_event.stub('id') { 'stripe_event_id' }
      mock_event.stub('created') { 1394531936 }
      mock_event.stub_chain('data.object.amount_refunded') { 2000 }
    end

    it 'should create a refunded revenue event' do
      StripeWebhookHandler.charge_refunded(mock_event)

      revenue_event = RevenueEvent.last
      expect(revenue_event.event).to eq RevenueEvent::REFUNDED
      expect(revenue_event.amount).to eq 2000
      expect(revenue_event.created_at).to eq Time.at(1394531936)
      expect(revenue_event.stripe_id).to eq 'stripe_event_id'
    end
  end

  describe '.charge_failed' do
    let!(:mock_event) { double }
    let!(:user) { create :user }
    let!(:subscription) { create :subscription, user: user }

    before do
      mock_event.stub_chain('data.object.customer') { 'cus_fake' }
      mock_event.stub_chain('data.object.invoice') { 'inv_001' }
    end

    context 'when there is a matching user and an invoice for the ids provided by Stripe' do
      let!(:invoice) { instance_double 'Stripe::Invoice' }
      let!(:plan) { create :plan }

      before do
        User.stub(:find_by_stripe_customer_id).with('cus_fake') { user }
        Stripe::Invoice.stub(:retrieve).with('inv_001') { invoice }
      end

      context "when there's a subscription associated with the user" do
        let!(:subscription) { create :subscription, user: user }

        it "should call charge_failed on user's subscription" do
          expect(user.subscription).to receive(:charge_failed).with(invoice)
          StripeWebhookHandler.charge_failed(mock_event)
        end
      end

      context "when there's no subscription associated with the user" do
        let!(:user_without_subscription) { create :user }

        before do
          User.stub(:find_by_stripe_customer_id).with('cus_fake') { user_without_subscription }
        end

        it 'should return without calling charge_failed on any subscription' do
          expect_any_instance_of(Subscription).to_not receive(:charge_failed)
          StripeWebhookHandler.charge_failed(mock_event)
        end
      end
    end

    context 'when a user cannot be found for the customer id provided by Stripe' do
      before do
        User.stub(:find_by_stripe_customer_id).with('cus_fake') { nil }
      end

      it 'should return without calling charge_failed on any subscription' do
        expect_any_instance_of(Subscription).to_not receive(:charge_failed)
        StripeWebhookHandler.charge_failed(mock_event)
      end
    end

    context 'when an invoice cannot be found for the invoice id provided by Stripe' do
      before do
        User.stub(:find_by_stripe_customer_id).with('cus_fake') { user }
        user.stub(:subscription) { subscription }

        Stripe::Invoice.stub(:retrieve).with('inv_001') { nil }
      end

      it 'should return without calling charge_failed on any subscription' do
        expect_any_instance_of(Subscription).to_not receive(:charge_failed)
        StripeWebhookHandler.charge_failed(mock_event)
      end
    end
  end

  describe '.charge_refunded' do
    let!(:mock_event) { double }

    before do
      mock_event.stub('id') { 'stripe_event_id' }
      mock_event.stub('created') { 1394531936 }
      mock_event.stub_chain('data.object.amount_refunded') { 2000 }
    end

    it 'should create a refunded revenue event' do
      StripeWebhookHandler.charge_refunded(mock_event)

      revenue_event = RevenueEvent.last
      expect(revenue_event.event).to eq RevenueEvent::REFUNDED
      expect(revenue_event.amount).to eq 2000
      expect(revenue_event.created_at).to eq Time.at(1394531936)
      expect(revenue_event.stripe_id).to eq 'stripe_event_id'
    end
  end
end
