require 'spec_helper'

describe Subscription do
  it { should belong_to(:billing_profile) }
  it { should belong_to(:subscription_plan) }

  describe 'validations' do
    let!(:subscription) { create :subscription }

    it { should validate_presence_of(:billing_profile_id) }
    it { should validate_presence_of(:subscription_plan_id) }
  end

  describe 'state machine' do
    let!(:subscription) { create :subscription }

    describe '#activate' do
      before { subscription.update_attribute :state, 'pending' }

      it 'changes the subscription state to active' do
        expect {
          subscription.activate!
        }.to change { subscription.state }.from('pending').to('active')
      end

      it 'fills n2o to the user account' do
        subscription.activate!

        user = subscription.billing_profile.user
        plan = subscription.subscription_plan
        n2o_fill = user.n2o_fills.last
        expect(n2o_fill.amount).to eq(plan.n2o_amount)
        expect(n2o_fill.kind).to eq(N2oFill::Kind::PURCHASE)
      end
    end
  end

  describe '.create_from_stripe' do
    let!(:customer_stripe_id) { "cus_0001" }
    let!(:plan_stripe_id) { "plan_0001" }
    let!(:billing_profile) { create :billing_profile, stripe_id: customer_stripe_id }
    let!(:subscription_plan) { create :subscription_plan, stripe_id: plan_stripe_id }

    context 'when billing profile and subscription plan for given stripe ids exisit' do
      it "should create an active subscription with the billing profile and subscritpion plan assoicated to stripe ids" do
        expect {
          Subscription.create_from_stripe customer_stripe_id, plan_stripe_id
        }.to change { Subscription.count }.by 1

        subscription = Subscription.last
        expect(subscription.billing_profile).to eq(billing_profile)
        expect(subscription.subscription_plan).to eq(subscription_plan)
        expect(subscription.state).to eq("active")
      end
    end

    context 'when billing profile and subscription plan for given stripe ids doesnt exisit' do
      it "should raise an error" do
        expect {
          Subscription.create_from_stripe "some_stripe_customer_id", "some_stripe_plan_id"
        }.to raise_error
      end
    end
  end
end
