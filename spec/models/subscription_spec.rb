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

          it 'creates a delayed to push subscription updated message' do
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

            it 'does not tracks the event in mixpanel' do
              user = subscription.user

              # stub the N2oFill#save to avoid it calling the SetMixpanelPropertyJob
              allow_any_instance_of(N2oFill).to receive(:save!).and_return(true)

              TrackMixpanelEventJob.should_not_receive(:submit_job).with('Subscribed To Plan', user.id, { plan: subscription.plan.name })
              SetMixpanelPropertyJob.should_not_receive(:submit_job).with(user.id, { paid_user: true, plan: subscription.plan.name })

              subscription.activate!(:changing_plans)
            end

            it 'creates a delayed to push subscription updated message' do
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

  describe '#charge_failed', focus: true  do
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
end
