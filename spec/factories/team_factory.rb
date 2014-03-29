FactoryGirl.define do
  factory :team do
    sequence(:name)           { |n| "team#{n}" }
    association(:org)         { factory :org   }
  end
end

