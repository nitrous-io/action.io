FactoryGirl.define do
  factory :user do
    sequence(:username)  { |n| "user#{n}" }
    sequence(:email)     { |n| "user#{n}@example.com" }
    sequence(:full_name) { |n| "User #{n}" }
    password '123456'
    password_confirmation '123456'

    ignore do
      invite_code nil
    end

    factory :admin do
      admin true
    end

    factory :external_authenticated_user do
      ignore do
        username nil
      end

      after :build do |user, evaluator|
        authentication = build :authentication
        user.authentications << authentication
      end
    end

    after(:build) do |user, evaluator|
      unless user.admin?
        user.invite_code = evaluator.invite_code || Digest::SHA1.hexdigest("#{user.email}-#{Time.now.to_i}")[0...7]
        FactoryGirl.create(:invite, invite_code: user.invite_code, email: user.email, state: 'activated')
      end
    end
  end
end
