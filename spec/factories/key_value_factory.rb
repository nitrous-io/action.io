FactoryGirl.define do
  factory :key_value do
    sequence(:key) { |n| "key#{n}" }
  end
end
