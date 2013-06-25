FactoryGirl.define do
  factory :user do
    sequence(:username)  { |n| "user#{n}" }
    sequence(:email)     { |n| "user#{n}@example.com" }
    sequence(:full_name) { |n| "User #{n}" }
    password '123456'
    password_confirmation '123456'
    confirmed_at         { Time.now }

    factory :admin do
      admin true
    end

    factory :unconfirmed_user do
      confirmed_at nil
    end

    factory :external_authenticated_user do
      ignore do
        username nil
      end

      after :build do |user, evaluator|
        authentication = build :authentication, user: nil
        user.authentications << authentication
      end
    end
  end
end
