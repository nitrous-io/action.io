FactoryGirl.define do
  factory :boxhost do
    sequence(:name) { |n| "boxhost-#{n}" }
    association :owner, factory: :user
    association :location
    association :boxhost_plan
  end
end
