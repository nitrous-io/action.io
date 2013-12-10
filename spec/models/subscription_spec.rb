require 'spec_helper'

describe Subscription do
  it { should allow_mass_assignment_of :plan }
  it { should allow_mass_assignment_of :user }

  it { should belong_to(:user) }
  it { should belong_to(:plan) }

  describe 'validations' do
    let!(:subscription) { create :subscription }

    it { should validate_presence_of(:plan) }
  end

  describe 'state machine' do
    let!(:subscription) { create :subscription }

    before { PushSubscriptionUpdatedJob.stub(:submit_job).with(subscription.id) }

    describe '#activate' do
      ['pending', 'canceled'].each do |initial_state|
        context "when initial state is #{initial_state}" do
          before do
            subscription.update_attribute :state, initial_state
          end

          it 'changes the subscription state to active' do
            expect {
              subscription.activate!
            }.to change { subscription.state }.from(initial_state).to('active')
          end

          it 'fills n2o to the user account' do
            subscription.activate!

            plan = subscription.plan
            n2o_fill = N2oFill.last
            expect(n2o_fill.resource).to eq(subscription)
            expect(n2o_fill.kind).to eq(N2oFill::Kind::PURCHASE)
            expect(n2o_fill.amount).to eq(plan.n2o_amount)
            expect(n2o_fill.user).to eq(subscription.user)
          end

          it 'tracks the event in mixpanel' do
            user = subscription.user

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
            create :box, owner: subscription.user
            create :box, users: [ subscription.user ]
            create :box

            expect_any_instance_of(Box).to receive(:update_premium).once
            subscription.activate!
          end

          it 'creates a delayed job to push subscription updated message' do
            PushSubscriptionUpdatedJob.should_receive(:submit_job).with(subscription.id)
            subscription.activate!
          end

          context 'when changing plans' do
            it 'does not update the premium flag of boxes owned by the user' do
              create :box, owner: subscription.user
              create :box, users: [ subscription.user ]
              create :box

              expect_any_instance_of(Box).to_not receive(:update_premium)
              subscription.activate!(:changing_plans)
            end

            it 'does not track the event in mixpanel' do
              user = subscription.user

              # stub the N2oFill#save to avoid it calling the SetMixpanelPropertyJob
              allow_any_instance_of(N2oFill).to receive(:save!).and_return(true)

              TrackMixpanelEventJob.should_not_receive(:submit_job).with('Subscribed To Plan', user.id, { plan: subscription.plan.name })
              SetMixpanelPropertyJob.should_not_receive(:submit_job).with(user.id, { paid_user: true, plan: subscription.plan.name })

              subscription.activate!(:changing_plans)
            end

            it 'creates a delayed job to push subscription updated message' do
              PushSubscriptionUpdatedJob.should_receive(:submit_job).with(subscription.id)
              subscription.activate!(:changing_plans)
            end
          end
        end
      end
    end

    describe '#cancel' do
      context "when initial state is active" do
        before do
          subscription.update_attribute :state, 'active'
          subscription.send :fill_n2o!
        end

        it 'changes the subscription state to canceled' do
          expect {
            subscription.cancel!
          }.to change { subscription.state }.from('active').to('canceled')
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

        it 'archives the subscription as a new PastSubscription' do
          PastSubscription.should_receive(:archive).with(subscription)
          subscription.cancel!
        end

        it "sends a 'subscription canceled' email to the user" do
          SubscriptionMailer.should_receive(:subscription_canceled).with(subscription.id) { double.as_null_object }
          subscription.cancel!
          Delayed::Job.last.invoke_job
        end

        it 'updates premium flag on all boxes owned by the user' do
          create :box, owner: subscription.user
          create :box, users: [ subscription.user ]
          create :box

          expect_any_instance_of(Box).to receive(:update_premium).once
          subscription.cancel!
        end

        it 'creates a delayed job to push subscription updated message' do
          PushSubscriptionUpdatedJob.should_receive(:submit_job).with(subscription.id)
          subscription.cancel!
        end

        context 'when changing plans' do
          it 'does not update the premium flag of boxes owned by the user' do
            create :box, owner: subscription.user
            create :box, users: [ subscription.user ]
            create :box

            expect_any_instance_of(Box).to_not receive(:update_premium)
            subscription.cancel!(:changing_plans)
          end

          it 'does not create a delayed job to push subscription updated message' do
            PushSubscriptionUpdatedJob.should_not_receive(:submit_job).with(subscription.id)
            subscription.cancel!(:changing_plans)
          end

          it "does not track the event in mixpanel" do
            user = subscription.user

            # stub the N2oFill#destroy to avoid it calling the SetMixpanelPropertyJob
            allow_any_instance_of(N2oFill).to receive(:destroy).and_return(nil)

            TrackMixpanelEventJob.should_not_receive(:submit_job).with('Unsubscribed From Plan', user.id, { plan: subscription.plan.name })
            SetMixpanelPropertyJob.should_not_receive(:submit_job).with(user.id, { paid_user: false, plan: nil })
            subscription.cancel!(:changing_plans)
          end
        end
      end
    end
  end

  describe '#charge_failed' do
    let!(:subscription) { create :subscription }

    it 'sets payment_due property in subscription to true' do
      subscription.charge_failed
      expect(subscription.reload.payment_due).to eq(true)
    end

    it 'tracks the payment failure in Mixpanel' do
      user = subscription.user

      TrackMixpanelEventJob.should_receive(:submit_job).with('Payment Failed', user.id, { plan: subscription.plan.name })
      subscription.charge_failed
    end

    it 'sends a notice to user informing the payment failure' do
      SubscriptionMailer.should_receive(:payment_failed_alert).with(subscription.id) { double.as_null_object }
      subscription.charge_failed
      Delayed::Job.last.invoke_job
    end

  end

  describe '#change_plan!', focus: true do
    let!(:current_plan) { create :plan, n2o_amount: 500 }
    let!(:new_plan) { create :plan, n2o_amount: 1000 }
    let!(:subscription) { create :subscription, plan: current_plan }
    let!(:user) { create :user, subscription: subscription, max_n2o: current_plan.n2o_amount } # just assuming base N2O is 0

    context 'when given plan is same as the current plan' do
      it 'returns false' do
        expect(subscription.change_plan!(current_plan)).to eq(false)
      end
    end

    context 'when given plan is different from the current plan' do
      before do
        DowngradeBoxesJob.stub(:submit_job)
        TrackMixpanelEventJob.stub(:submit_job)
      end

      it 'sets the given plan as the current plan' do
        subscription.change_plan!(new_plan)
        expect(subscription.reload.plan).to eq(new_plan)
      end

      it 'assigns correct n2o fill to the user' do
        base_n2o = user.max_n2o - current_plan.n2o_amount

        subscription.change_plan!(new_plan)

        expect(user.reload.max_n2o).to eq(base_n2o + new_plan.n2o_amount)
      end

      it 'archives the subscription as a new PastSubscription' do
        PastSubscription.should_receive(:archive).with(subscription)
        subscription.change_plan!(new_plan)
      end

      it "sends a 'subscription activated' email to the user" do
        SubscriptionMailer.should_receive(:subscription_activated).with(subscription.id) { double.as_null_object }
        subscription.change_plan!(new_plan)
        Delayed::Job.last.invoke_job
      end

      context 'when new plan is a spec downgrade from current plan' do
        before do
          new_plan.stub(:is_spec_downgrade_from) { true }
        end

        it 'submits a job to downgrade boxes' do
          DowngradeBoxesJob.should_receive(:submit_job).with(user.id)
          subscription.change_plan!(new_plan)
        end
      end

      context 'when new plan is a price downgrade from current plan' do
        before do
          new_plan.stub(:is_price_downgrade_from) { true }
        end

        it 'submits a job to track downgrade event in Mixpanel' do
          TrackMixpanelEventJob.should_receive(:submit_job).with('Downgraded Plan', user.id, from: current_plan.name, to: new_plan.name)
          subscription.change_plan!(new_plan)
        end

      end

      context 'when new plan is a price upgrade from current plan' do
        before do
          new_plan.stub(:is_price_downgrade_from) { false }
        end

        it 'submits a job to track upgrade event in Mixpanel' do
          TrackMixpanelEventJob.should_receive(:submit_job).with('Upgraded Plan', user.id, from: current_plan.name, to: new_plan.name)
          subscription.change_plan!(new_plan)
        end
      end
    end
  end
end
