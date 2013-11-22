require 'spec_helper'

describe BillingProfile do
  it { should belong_to(:user) }
  it { should have_many(:receipts) }
  it { should have_many(:subscriptions) }

  describe '#push_billing_profile_updated_message' do
    let!(:user) { create :user }
    let!(:billing_profile) { create :billing_profile, user: user }

    it 'pushes aio:billing_profile_updated notification' do
      channel = double('channel')
      Pusher.should_receive(:[]).with("private-user-#{user.id}") { channel }
      channel.should_receive(:trigger).ordered.with('aio:billing_profile_updated', billing_profile.serialize_as_hash)

      billing_profile.push_billing_profile_updated_message
    end
  end

  describe '.handle_event_from_stripe' do
    let!(:stripe_id) { "stripe_id" }
    let!(:subscription_plan) { create :subscription_plan, stripe_id: stripe_id }
    let!(:billing_profile) { create :billing_profile }

    let!(:subscription_1) { create :subscription, billing_profile: billing_profile, subscription_plan: subscription_plan }
    let!(:subscription_2) { create :subscription, billing_profile: billing_profile, subscription_plan: subscription_plan }

    before do
      allow_any_instance_of(BillingProfile).to receive(:push_billing_profile_updated_message)
    end

    context 'when a billing profile exist for the given stripe id' do
      context 'the event is subscription_created' do
        context 'when an active subscription doesnt exist for the billing profile' do
          it 'creates an active subscription for the given plan' do
            expect {
              BillingProfile.handle_event_from_stripe stripe_id, 'subscription_created', { plan_id: stripe_id }
            }.to change { Subscription.count }.by 1

            subscription = Subscription.last
            expect(subscription.billing_profile).to eq(billing_profile)
            expect(subscription.subscription_plan).to eq(subscription_plan)
            expect(subscription.state).to eq("active")
          end
        end

        context 'when an active subscription exist for the billing profile ' do
          before do
            create :subscription, state: 'active', subscription_plan: subscription_plan, billing_profile: billing_profile
          end

          it 'does not create another subscription' do
            expect {
              BillingProfile.handle_event_from_stripe stripe_id, 'subscription_created', { plan_id: stripe_id }
            }.to_not change { Subscription.count }
          end
        end
      end

      context 'the event is charge_failed' do
        before do
          subscription_1.update_attribute 'state', 'canceled'
          subscription_2.update_attribute 'state', 'active'
        end

        it 'changes active subscription to payment due' do
          BillingProfile.handle_event_from_stripe stripe_id, 'charge_failed'
          expect(subscription_2.reload.state).to eq('payment_due')
        end
      end

      context 'the event is subscription_changed' do
        before do
          subscription_1.update_attribute 'state', 'canceled'
          subscription_2.update_attribute 'state', 'active'
        end

        it 'cancels the active subscription' do
          BillingProfile.handle_event_from_stripe stripe_id, 'subscription_changed', { plan_id: stripe_id }
          expect(subscription_2.reload.state).to eq('canceled')
        end

        it 'creates an active subscription for the given plan' do
          expect {
            BillingProfile.handle_event_from_stripe stripe_id, 'subscription_changed', { plan_id: stripe_id }
          }.to change { Subscription.count }.by 1

          subscription = Subscription.last
          expect(subscription.billing_profile).to eq(billing_profile)
          expect(subscription.subscription_plan).to eq(subscription_plan)
          expect(subscription.state).to eq("active")
        end
      end

      context 'the event is subscription_canceled' do
        before do
          subscription_1.update_attribute 'state', 'canceled'
          subscription_2.update_attribute 'state', 'active'
        end

        it 'cancels the active subscription' do
          BillingProfile.handle_event_from_stripe stripe_id, 'subscription_canceled'
          expect(subscription_2.reload.state).to eq('canceled')
        end
      end

      context 'the event is payment_succeeded' do
        before do
          subscription_1.update_attribute 'state', 'canceled'
          subscription_2.update_attribute 'state', 'active'
        end

        let!(:period_start) { Time.new(2013, 10, 1) }
        let!(:period_end) { Time.new(2013, 10, 31) }
        let!(:receipt_details) do
          {
            period_start: period_start.to_i,
            period_end: period_end.to_i,
            lines: [{
              "amount" => 500,
              "currency" => "usd",
              "quantity" => 1,
              "description" => nil,
              "plan" => {
                "name" => "500 N2O"
              }
            }],
            subtotal: 500,
            total: 500
          }
        end

        it 'creates a new receipt for the billing profile' do
          expect {
            BillingProfile.handle_event_from_stripe stripe_id, 'payment_succeeded', { receipt_details: receipt_details }
          }.to change { Receipt.count }.by 1

          receipt = Receipt.last
          expect(receipt.billing_profile).to eq(billing_profile)
          expect(receipt.period_start).to eq(period_start)
          expect(receipt.period_end).to eq(period_end)
          expect(receipt.subtotal).to eq(500)
          expect(receipt.total).to eq(500)
          expect(receipt.lines).to eq(receipt_details[:lines])
        end

        it "should track revenue on Mixpanel" do
          user = billing_profile.user
          TrackMixpanelRevenueJob.should_receive(:submit_job).with(user.id, subscription_plan.price)
          BillingProfile.handle_event_from_stripe stripe_id, 'payment_succeeded', { receipt_details: receipt_details }
        end
      end

      context 'the event is card_updated' do
        it 'sends a mail notifying the user that the card has been updated' do
          BillingProfile.handle_event_from_stripe stripe_id, 'card_updated'
          SubscriptionMailer.should_receive(:credit_card_changed_alert).with(billing_profile.id) { double(:nothing, deliver: nil) }
          Delayed::Job.last.invoke_job
        end
      end
    end
  end

  describe '.find_profiles_with_expiring_cards', focus: true do
    let!(:billing_profile_1) { create :billing_profile, exp_month: 9, exp_year: 2013 }
    let!(:billing_profile_2) { create :billing_profile, exp_month: 9, exp_year: 2013 }
    let!(:billing_profile_3) { create :billing_profile, exp_month: 11, exp_year: 2013 }

    let!(:subscription_1) { create :subscription, state: 'active', billing_profile: billing_profile_1, subscription_plan: subscription_plan }
    let!(:subscription_2) { create :subscription, state: 'canceled', billing_profile: billing_profile_2, subscription_plan: subscription_plan }
    let!(:subscription_3) { create :subscription, state: 'active', billing_profile: billing_profile_3, subscription_plan: subscription_plan }

    context 'when a valid date is provided' do
      before do
        @date = Time.utc(2013, 9)
      end

      it 'should return only active profiles expiring in the given month' do
        BillingProfile.find_profiles_with_expiring_cards(@date).should eq [billing_profile_1]
      end
    end

    context 'when the date is nil' do
      before do
        @date = nil
      end

      it 'should not return any profiles' do
        BillingProfile.find_profiles_with_expiring_cards(@date).should eq nil
      end
    end
  end

end
