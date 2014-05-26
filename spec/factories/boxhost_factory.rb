FactoryGirl.define do
  factory :boxhost do
    sequence(:name) { |n| "boxhost-#{n}" }
    association :owner, factory: :user
  end
end
