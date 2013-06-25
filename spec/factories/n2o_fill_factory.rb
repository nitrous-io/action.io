FactoryGirl.define do
  factory :n2o_fill do
    association :user, factory: :user
    amount 0
    kind 0
    description 'n2o fill up'
  end
end
