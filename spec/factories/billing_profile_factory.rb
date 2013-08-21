FactoryGirl.define do
  factory :billing_profile do
    association :user, factory: :user
  end
end
