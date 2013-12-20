require 'spec_helper'

describe PastSubscription do
  it { should allow_mass_assignment_of :user }
  it { should allow_mass_assignment_of :plan_name }
  it { should allow_mass_assignment_of :plan_stripe_id }
  it { should allow_mass_assignment_of :plan_price }
  it { should allow_mass_assignment_of :plan_interval }
  it { should allow_mass_assignment_of :plan_n2o_amount }

  it { should belong_to(:user) }

  describe '.archive' do
    let!(:user) { create :user }
    let!(:plan) { create :plan, name:'Nitro', stripe_id: 'n2o_5000', price: 79.99, interval: 'month', n2o_amount: 5000 }
    let!(:subscription) { create :subscription, user: user, plan: plan }

    it 'should create a new PastSubscription instance from the given Subscription and its Plan' do
      expect {
        PastSubscription.archive(subscription)
      }.to change { PastSubscription.count }.by(1)

      past_subscription = PastSubscription.last
      expect(past_subscription.user_id).to eq(user.id)
      expect(past_subscription.plan_name).to eq('Nitro')
      expect(past_subscription.plan_stripe_id).to eq('n2o_5000')
      expect(past_subscription.plan_price).to eq(79.99)
      expect(past_subscription.plan_interval).to eq('month')
      expect(past_subscription.plan_n2o_amount).to eq(5000)
    end
  end
end
