FactoryGirl.define do
  factory :boxhost_key_pair do
    sequence(:private_key)  { |n| "boxhost-private-key-#{n}" }
    sequence(:public_key)   { |n| "boxhost-public-key-#{n}" }
    boxhost
  end
end
