FactoryGirl.define do
  factory :subscription do
    association :plan
    association :user
  end
end
