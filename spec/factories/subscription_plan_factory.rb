FactoryGirl.define do
  factory :subscription_plan do
    sequence(:name)           { |n| "plan-#{n}" }
    sequence(:price)          { |n| n }
    sequence(:stripe_id)      { |n| "stripe-id-#{n}" }
    sequence(:n2o_amount)     { |n| n * 100 }
    interval                  'month'
  end
end
