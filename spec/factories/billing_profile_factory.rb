FactoryGirl.define do
  factory :billing_profile do
    association :user, factory: :user
    sequence(:stripe_id)           { |n| "cus-#{n}" }

    last_four "1234"
    card_type "Visa"
    exp_month 9
    exp_year  2013

  end
end
