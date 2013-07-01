FactoryGirl.define do
  factory :invite do
    sequence(:email) { |n| "invite#{n}@gmail.com" }
    state 'activated'

    association :inviting_user, factory: :user
  end
end
