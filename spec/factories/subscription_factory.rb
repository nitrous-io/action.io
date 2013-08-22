FactoryGirl.define do
  factory :subscription do
    association :subscription_plan, factory: :subscription_plan
    association :billing_profile, factory: :billing_profile
  end
end
