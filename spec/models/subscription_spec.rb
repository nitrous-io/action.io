require 'spec_helper'

describe Subscription do
  it { should allow_mass_assignment_of :plan }

  it { should belong_to(:billing_profile) }
  it { should belong_to(:plan) }

  describe 'validations' do
    let!(:subscription) { create :subscription }

    it { should validate_presence_of(:billing_profile_id) }
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

    before do
      subscription.billing_profile.should_receive(:push_billing_profile_updated_message)
    end

    describe '#activate' do
      before { subscription.update_attribute :state, 'pending' }

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

        TrackMixpanelEventJob.should_receive(:submit_job).with('Subscribed to a plan', user.id, { plan_name: subscription.plan.name })
        SetMixpanelPropertyJob.should_receive(:submit_job).with(user.id, { paid_user: true, plan: subscription.plan.name })

        subscription.activate!
      end

      it "sends a 'subscription activated' email to the user" do
        SubscriptionMailer.should_receive(:subscription_activated).with(subscription.id) { double.as_null_object }
        subscription.activate!
        Delayed::Job.last.invoke_job
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
            TrackMixpanelEventJob.should_receive(:submit_job).with('Payment failed', user.id, { plan_name: subscription.plan.name })
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
            user = subscription.billing_profile.user

            # stub the N2oFill#destroy to avoid it calling the SetMixpanelPropertyJob
            allow_any_instance_of(N2oFill).to receive(:destroy).and_return(nil)

            TrackMixpanelEventJob.should_receive(:submit_job).with('Unsubscribed from a plan', user.id, { plan_name: subscription.plan.name })
            SetMixpanelPropertyJob.should_receive(:submit_job).with(user.id, { paid_user: false, plan: nil })

            subscription.cancel!
          end
        end
      end
    end
  end
end
