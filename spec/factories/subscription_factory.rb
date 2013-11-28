FactoryGirl.define do
  factory :subscription do
    association :plan, factory: :subscription_plan
    association :billing_profile
  end
end
