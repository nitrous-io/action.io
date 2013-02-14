FactoryGirl.define do
  factory :authentication do
    association :user, factory: :user
    provider 'github'
    sequence(:uid) { |n| "#{n}" }
    sequence(:token) { |n| "someToken#{n}" }
  end
end
