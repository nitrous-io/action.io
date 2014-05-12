FactoryGirl.define do
  factory :user_settings do
    association :user, factory: :user
  end
end
