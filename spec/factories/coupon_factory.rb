FactoryGirl.define do
  factory :coupon do
    sequence(:code)  { |n| "code#{n}" }
    active           true
    percent_off      100
    duration         2
  end
end
