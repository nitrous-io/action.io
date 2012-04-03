FactoryGirl.define do
  factory :authentication do
    user
    provider 'github'
    uid '123456'
  end
end
