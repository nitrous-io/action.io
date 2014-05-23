FactoryGirl.define do
  factory :boxhost_provider_template do
    sequence(:provider) { |n| "provider-n" }
    sequence(:name) { |n| "template-#{n}" }
    association :boxhost_plan
    association :location
  end
end
