FactoryGirl.define do
  factory :user do
    username { Faker::Internet.user_name }
    email { Faker::Internet.email }
    full_name { Faker::Name.name }
    password '123456'
    password_confirmation '123456'
  end
end
