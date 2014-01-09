FactoryGirl.define do
  factory :deleted_user do
    sequence(:user_id)   { |n| n }
    sequence(:username)  { |n| "user#{n}" }
    sequence(:email)     { |n| "user#{n}@gmail.com" }
  end
end
