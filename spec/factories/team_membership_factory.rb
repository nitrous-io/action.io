FactoryGirl.define do
  factory :team_membership do
    association :member, factory: :user
    association :team
  end
end

