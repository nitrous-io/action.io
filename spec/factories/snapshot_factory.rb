FactoryGirl.define do
  factory :snapshot do
    sequence(:name) { |n| "snapshot#{n}" }
    association :user
    association :box, factory: :box
    sequence(:url) { |n| "http://s3.com/snapshot#{n}" }
  end
end
