FactoryGirl.define do
  factory :user do
    username { begin; u = Faker::Internet.user_name; end while u.length < 4 || u.length > 20; u }
    email { Faker::Internet.email }
    full_name { begin; n = Faker::Name.name; end while n.length > 40; n }
    password '123456'
    password_confirmation '123456'

    factory :user_with_invite do
      ignore do
        invite_code nil
      end

      after(:build) do |user, evaluator|
        user.invite_code = evaluator.invite_code || Digest::SHA1.hexdigest("#{user.email}-#{Time.now.to_i}")[0...7]
        FactoryGirl.create(:invite, invite_code: user.invite_code, email: user.email)
      end
    end
  end
end
