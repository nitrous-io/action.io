FactoryGirl.define do
  factory :snapshot do
    sequence(:name) { |n| "snapshot#{n}" }
    sequence(:url) { |n| "s3://host/snapshot#{n}" }
    state 'born'
    box
  end
end
