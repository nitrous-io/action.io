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
      past_subscription.user_id.should == user.id
      past_subscription.plan_name.should == 'Nitro'
      past_subscription.plan_stripe_id.should == 'n2o_5000'
      past_subscription.plan_price.should == 79.99
      past_subscription.plan_interval.should == 'month'
      past_subscription.plan_n2o_amount.should == 5000
    end
  end
end
