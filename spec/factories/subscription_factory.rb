FactoryGirl.define do
  factory :subscription do
    user
    plan
    started_at { Time.now }
  end
end
