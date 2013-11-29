FactoryGirl.define do
  factory :subscription do
    association :plan, factory: :plan
    association :billing_profile
  end
end
