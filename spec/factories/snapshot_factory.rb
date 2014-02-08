FactoryGirl.define do
  factory :snapshot do
    sequence(:name) { |n| "snapshot#{n}" }
    association :user
    association :box, factory: :box
  end
end
