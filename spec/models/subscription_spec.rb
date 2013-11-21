require 'spec_helper'

describe Subscription do
  it { should allow_mass_assignment_of :subscription_plan }

  it { should belong_to(:billing_profile) }
  it { should belong_to(:subscription_plan) }

  describe 'validations' do
    let!(:subscription) { create :subscription }

    it { should validate_presence_of(:billing_profile_id) }
    it { should validate_presence_of(:subscription_plan_id) }
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
      create :box, owner: subscription.billing_profile.user
      subscription.billing_profile.should_receive(:push_billing_profile_updated_message)
    end

    describe '#activate' do
      before do
        subscription.update_attribute :state, 'pending'

        expect_any_instance_of(Coach).to receive(:update_premium).and_return(nil)
      end

      it 'changes the subscription state to active' do
        expect {
          subscription.activate!
        }.to change { subscription.state }.from('pending').to('active')
      end

      it 'fills n2o to the user account' do
        subscription.activate!

        plan = subscription.subscription_plan
        n2o_fill = N2oFill.last
        expect(n2o_fill.resource).to eq(subscription)
        expect(n2o_fill.kind).to eq(N2oFill::Kind::PURCHASE)
        expect(n2o_fill.amount).to eq(plan.n2o_amount)
        expect(n2o_fill.user).to eq(subscription.billing_profile.user)
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

            expect_any_instance_of(Coach).to receive(:update_premium).and_return(nil)
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
        end
      end
    end
  end
end
