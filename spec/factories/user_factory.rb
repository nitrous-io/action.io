FactoryGirl.define do
  factory :user do
    username { begin; u = Faker::Internet.user_name; end while u.length < 4 || u.length > 20; u }
    email { Faker::Internet.email }
    full_name { begin; n = Faker::Name.name; end while n.length > 40; n }
    password '123456'
    password_confirmation '123456'
  end
end
