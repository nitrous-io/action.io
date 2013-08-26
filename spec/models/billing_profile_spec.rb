require 'spec_helper'
require 'ostruct'

describe BillingProfile do
  it { should allow_mass_assignment_of :stripe_token }
  it { should allow_mass_assignment_of :plan }

  it { should belong_to(:user) }
  it { should have_many(:subscriptions) }

  describe 'after_save callback' do
    let!(:stripe_token) { "stripe_token" }
    let!(:user) { create :user }
    let!(:plan) { create :subscription_plan }
    let!(:billing_profile) { create :billing_profile, user: user }

    before do
      billing_profile.stripe_token = stripe_token
      billing_profile.plan = plan
    end

    it "calls CreateOrUpdateStripeCustomerJob with profile id, user email, description, stripe token and selected plan id" do
      CreateOrUpdateStripeCustomerJob.should_receive(:submit_job).with(billing_profile.id, user.email, "#{user.username} #{user.email}", stripe_token, plan.id)
      billing_profile.save
    end

    it 'clears the stripe token' do
      billing_profile.save
      expect(billing_profile.stripe_token).to be_nil
    end
  end

  describe '.handle_event_from_stripe' do
    let!(:stripe_id) { "stripe_id" }
    let!(:billing_profile) { create :billing_profile, stripe_id: stripe_id }
    let!(:subscription_plan) { create :subscription_plan, stripe_id: stripe_id }

    let!(:subscription_1) { create :subscription, billing_profile: billing_profile }
    let!(:subscription_2) { create :subscription, billing_profile: billing_profile }

    context 'when a billing profile exist for the given stripe id' do
      before do
        subscription_1.update_attribute 'state', 'canceled'
        subscription_2.update_attribute 'state', 'active'
      end

      context 'the event is subscription_created' do
        it 'creates an active subscription for the given billing profile and plan' do
          expect {
            BillingProfile.handle_event_from_stripe stripe_id, 'subscription_created', { plan_id: stripe_id }
          }.to change { Subscription.count }.by 1

          subscription = Subscription.last
          expect(subscription.billing_profile).to eq(billing_profile)
          expect(subscription.subscription_plan).to eq(subscription_plan)
          expect(subscription.state).to eq("active")
        end
      end

      context 'the event is charge_failed' do
        it 'changes active subscription to payment due' do
          BillingProfile.handle_event_from_stripe stripe_id, 'charge_failed'
          expect(subscription_2.reload.state).to eq('payment_due')
        end
      end

      context 'the event is subscription_canceled' do
        it 'cancels active subscription' do
          BillingProfile.handle_event_from_stripe stripe_id, 'subscription_canceled'
          expect(subscription_2.reload.state).to eq('canceled')
        end
      end

    end
  end
end
