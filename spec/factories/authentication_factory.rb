FactoryGirl.define do
  factory :authentication do
    association :user, factory: :user
    provider 'github'
    sequence(:uid) { |n| "#{n}" }
    sequence(:token) { |n| "someToken#{n}" }
    confirmed true

    factory :unconfirmed_authentication do
      confirmed false
    end
  end
end
