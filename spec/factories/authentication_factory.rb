FactoryGirl.define do
  factory :authentication do
    user
    provider 'github'
    sequence(:uid) { |n| "#{n}" }
    sequence(:token) { |n| "someToken#{n}" }
  end
end
