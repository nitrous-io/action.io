FactoryGirl.define do
  factory :plan do
    sequence(:name)           { |n| "plan-#{n}" }
    sequence(:price)          { |n| n }
    sequence(:interval)       'month'
    sequence(:stripe_id)      { |n| "stripe-id-#{n}" }
  end
end
