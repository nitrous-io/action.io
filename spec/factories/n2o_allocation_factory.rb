FactoryGirl.define do
  factory :n2o_allocation do
    association :user, factory: :user
    amount 0
    kind 0
    description 'n2o allocation'
  end
end
