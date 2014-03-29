FactoryGirl.define do
  factory :org do
    sequence(:name)           { |n| "org#{n}" }
    sequence(:billing_email)  { |n| "org-owner-#{n}@org.com" }
    association :owner, factory: :user
  end
end


