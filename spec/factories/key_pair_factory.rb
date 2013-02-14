FactoryGirl.define do
  factory :key_pair do
    sequence(:private_key)  { |n| "private-key-#{n}" }
    sequence(:public_key)   { |n| "public-key-#{n}" }
    box
  end
end
