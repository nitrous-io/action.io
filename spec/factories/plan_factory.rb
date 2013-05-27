FactoryGirl.define do
  factory :plan do
    sequence(:name) { |n| "plan#{n}" }
    active true
  end
end
