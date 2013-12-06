require 'spec_helper'

describe Subscription do
  it { should allow_mass_assignment_of :plan }
  it { should allow_mass_assignment_of :user }

  it { should belong_to(:user) }
  it { should belong_to(:plan) }

  describe 'validations' do
    let!(:subscription) { create :subscription }

    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:plan) }
  end

  describe 'scopes' do
    let!(:subscription_1) { create :subscription                        }
    let!(:subscription_2) { create :subscription, state: 'active'       }
    let!(:subscription_3) { create :subscription, state: 'payment_due'  }
    let!(:subscription_4) { create :subscription, state: 'canceled'     }

    describe '.active' do
      it 'should return all subscriptions that are not pending or canceled' do
        Subscription.active.to_a.should =~ [ subscription_2, subscription_3 ]
      end
    end
  end

  describe 'state machine' do
    let!(:subscription) { create :subscription }

    describe '#activate' do
      before do
        subscription.update_attribute :state, 'pending'
      end

      it 'changes the subscription state to active' do
        expect {
          subscription.activate!
        }.to change { subscription.state }.from('pending').to('active')
      end

      it 'fills n2o to the user account' do
        subscription.activate!

        plan = subscription.plan
        n2o_fill = N2oFill.last
        expect(n2o_fill.resource).to eq(subscription)
        expect(n2o_fill.kind).to eq(N2oFill::Kind::PURCHASE)
        expect(n2o_fill.amount).to eq(plan.n2o_amount)
        expect(n2o_fill.user).to eq(subscription.billing_profile.user)
      end

      it "tracks the event in mixpanel" do
        user = subscription.billing_profile.user

        # stub the N2oFill#save to avoid it calling the SetMixpanelPropertyJob
        allow_any_instance_of(N2oFill).to receive(:save!).and_return(true)

        TrackMixpanelEventJob.should_receive(:submit_job).with('Subscribed To Plan', user.id, { plan: subscription.plan.name })
        SetMixpanelPropertyJob.should_receive(:submit_job).with(user.id, { paid_user: true, plan: subscription.plan.name })

        subscription.activate!
      end

      it "sends a 'subscription activated' email to the user" do
        SubscriptionMailer.should_receive(:subscription_activated).with(subscription.id) { double.as_null_object }
        subscription.activate!
        Delayed::Job.last.invoke_job
      end

      it 'updates premium flag on all boxes owned by the user' do
        create :box, owner: subscription.billing_profile.user
        create :box, users: [ subscription.billing_profile.user ]
        create :box

        expect_any_instance_of(Box).to receive(:update_premium).once
        subscription.activate!
      end
    end

    describe '#payment_failed' do
      ['active', 'payment_due'].each do |initial_state|
        context "when initial state is #{initial_state}" do
          before do
            subscription.update_attribute :state, initial_state
          end

          it 'changes the subscription state to payment_due' do
            subscription.payment_failed!
            expect(subscription.reload.state).to eq('payment_due')
          end

          it "tracks the event in mixpanel" do
            user = subscription.billing_profile.user
            TrackMixpanelEventJob.should_receive(:submit_job).with('Payment Failed', user.id, { plan: subscription.plan.name })
            subscription.payment_failed!
          end

          it 'notifies payment failure to user' do
            subscription.payment_failed!

            SubscriptionMailer.should_receive(:payment_failed_alert).with(subscription.id) { double.as_null_object }
            Delayed::Job.last.invoke_job
          end
        end
      end
    end

    describe '#cancel' do
      ['payment_due', 'active'].each do |initial_state|
        context "when initial state is #{initial_state}" do
          before do
            subscription.update_attribute :state, initial_state
            subscription.send :fill_n2o!
          end

          it 'changes the subscription state to canceled' do
            expect {
              subscription.cancel!
            }.to change { subscription.state }.from(initial_state).to('canceled')
          end

          it 'empties n2o from the user account' do
            subscription.cancel!

            expect(subscription.reload.n2o_fill).to be_nil
          end

          it "tracks the event in mixpanel" do
            user = subscription.user

            # stub the N2oFill#destroy to avoid it calling the SetMixpanelPropertyJob
            allow_any_instance_of(N2oFill).to receive(:destroy).and_return(nil)

            TrackMixpanelEventJob.should_receive(:submit_job).with('Unsubscribed From Plan', user.id, { plan: subscription.plan.name })
            SetMixpanelPropertyJob.should_receive(:submit_job).with(user.id, { paid_user: false, plan: nil })
            subscription.cancel!
          end

          it 'updates premium flag on all boxes owned by the user' do
            create :box, owner: subscription.user
            create :box, users: [ subscription.user ]
            create :box

            expect_any_instance_of(Box).to receive(:update_premium).once
            subscription.cancel!
          end

          it 'archives the subscription as a new PastSubscription' do
            PastSubscription.should_receive(:archive).with(subscription)
            subscription.cancel!
          end
        end
      end
    end
  end

  describe '.handle_stripe_event' do
    let!(:stripe_customer_id) { 'stripe_customer_id' }
    let!(:user) { create :user, stripe_customer_id: stripe_customer_id }
    let!(:stripe_plan_id) { 'stripe_plan_id' }
    let!(:current_plan) { create :plan, stripe_id: stripe_plan_id }
    let!(:new_plan) { create :plan, stripe_id: 'stripe_plan_new_id' }

    context 'when handling the "subscription_created" event' do
      context 'when the subscription is active' do
        let!(:subscription) { create :subscription, user: user, plan: current_plan, state: 'active' }

        it 'does not assign its plan to the given plan' do
          subscription.should_not_receive(:plan=).with(current_plan)

          Subscription.handle_stripe_event 'subscription_created', stripe_customer_id, { plan_id: stripe_plan_id }
        end

        it 'does not activate the subscription again' do
          user.stub(:subscription) { subscription }

          subscription.should_not_receive(:activate!)

          Subscription.handle_stripe_event 'subscription_created', stripe_customer_id, { plan_id: stripe_plan_id }
        end
      end

      context 'when the subscription is not active' do
        let!(:subscription) { create :subscription, user: user, plan: current_plan, state: 'pending' }

        it 'assigns its plan to the given plan' do
          expect {
            Subscription.handle_stripe_event 'subscription_created', stripe_customer_id, { plan_id: 'stripe_plan_new_id' }
          }.to change { subscription.reload.plan }
        end

        it 'activates the subscription' do
          Subscription.handle_stripe_event 'subscription_created', stripe_customer_id, { plan_id: stripe_plan_id }

          subscription.reload.state.should == 'active'
        end
      end
    end

    context 'when handling the "charge_failed" event' do
      let!(:subscription) { create :subscription, user: user, plan: current_plan, state: 'active' }

      it 'changes the subscription to payment_due' do
        Subscription.handle_stripe_event 'charge_failed', stripe_customer_id
        subscription.reload.state.should == 'payment_due'
      end
    end

    context 'when handling the "subscription_changed" event' do
      let!(:subscription) { create :subscription, user: user, plan: current_plan, state: 'active' }

      it 'cancels the current subscription' do
        user.stub(:subscription) { subscription }
        subscription.should_receive(:cancel)

        Subscription.handle_stripe_event 'subscription_changed', stripe_customer_id, { plan_id: 'new_stripe_plan_id' }
      end

    end


    context 'when a billing profile exists for the given stripe id' do

      context 'subscription_changed event' do
        let!(:new_plan) { create :plan, stripe_id: 'new_stripe_plan_id' }

        before do
          subscription_1.update_attribute 'state', 'canceled'
          subscription_2.update_attribute 'state', 'active'
        end

        it 'cancels the active subscription' do
          BillingProfile.handle_stripe_event 'subscription_changed', stripe_id, { plan_id: 'new_stripe_plan_id' }
          expect(subscription_2.reload.state).to eq('canceled')
        end

        it 'creates an active subscription for the given plan' do
          expect {
            BillingProfile.handle_stripe_event 'subscription_changed', stripe_id, { plan_id: 'new_stripe_plan_id' }
          }.to change { Subscription.count }.by 1

          subscription = Subscription.last
          expect(subscription.billing_profile).to eq(billing_profile)
          expect(subscription.plan).to eq(new_plan)
          expect(subscription.state).to eq("active")
        end

        context 'when the new plan is a downgrade from the old plan' do
          before do
            Plan.stub(:find_by_stripe_id).with('new_stripe_plan_id') { new_plan }
            new_plan.stub(:is_downgrade_from).with(current_plan) { true }
          end

          it 'should queue a job to downgrade boxes if the new plan is a downgrade from the old plan' do
            DowngradeBoxesJob.should_receive(:submit_job).with(user.id)
            BillingProfile.handle_stripe_event 'subscription_changed', stripe_id, { plan_id: 'new_stripe_plan_id' }
          end
        end

        context 'when the new plan is not a downgrade from the old plan' do
          before do
            Plan.stub(:find_by_stripe_id).with('new_stripe_plan_id') { new_plan }
            new_plan.stub(:is_downgrade_from).with(current_plan) { false }
          end

          it 'should not queue a job to downgrade boxes if the new plan is not a downgrade from the old plan' do
            DowngradeBoxesJob.should_not_receive(:submit_job)
            BillingProfile.handle_stripe_event 'subscription_changed', stripe_id, { plan_id: 'new_stripe_plan_id' }
          end
        end
      end

      context 'subscription_canceled event' do
        before do
          subscription_1.update_attribute 'state', 'canceled'
          subscription_2.update_attribute 'state', 'active'
        end

        it 'cancels the active subscription' do
          BillingProfile.handle_stripe_event 'subscription_canceled', stripe_id
          expect(subscription_2.reload.state).to eq('canceled')
        end

        it 'should queue a job to downgrade boxes' do
          DowngradeBoxesJob.should_receive(:submit_job).with(user.id)
          BillingProfile.handle_stripe_event 'subscription_canceled', stripe_id
        end
      end

      context 'payment_succeeded event' do
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
            BillingProfile.handle_stripe_event 'payment_succeeded', stripe_id, { receipt_details: receipt_details }
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
          TrackMixpanelRevenueJob.should_receive(:submit_job).with(user.id, current_plan.price)
          BillingProfile.handle_stripe_event 'payment_succeeded', stripe_id, { receipt_details: receipt_details }
        end
      end

      context 'card_updated event' do
        it 'sends a notification mail to the user' do
          BillingProfile.handle_stripe_event 'card_updated', stripe_id
          SubscriptionMailer.should_receive(:credit_card_changed_alert).with(billing_profile.id) { double(:nothing, deliver: nil) }
          Delayed::Job.last.invoke_job
        end
      end
    end
  end
end
