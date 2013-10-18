FactoryGirl.define do
  factory :coupon do
    sequence(:code)           { |n| "coupon-#{n}" }
    sequence(:duration)       { |n| n }
    sequence(:percent_off)    { |n| n * 10 }

    active                    true
  end
end
