FactoryGirl.define do
  factory :invite do
    sequence(:email) { |n| "user#{n}@example.com" }
  end
end
