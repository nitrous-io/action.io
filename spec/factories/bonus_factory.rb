FactoryGirl.define do
  factory :bonus do
    association :user, factory: :user
  end
end
