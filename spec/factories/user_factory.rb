FactoryGirl.define do
  factory :user do
    username { begin; u = Faker::Internet.user_name; end while u.length < 4; u }
    email { Faker::Internet.email }
    full_name { Faker::Name.name }
    password '123456'
    password_confirmation '123456'
  end
end
