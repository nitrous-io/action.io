FactoryGirl.define do
  factory :subscription do
    subscription_plan { create :subscription_plan }
    billing_profile   { create :billing_profile, plan: subscription_plan }
  end
end
