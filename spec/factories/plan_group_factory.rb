FactoryGirl.define do
  factory :plan_group do
    sequence(:name) { |n| "plan group #{n}" }
  end
end
