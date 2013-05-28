FactoryGirl.define do
  factory :subscription do
    user
    plan
    started_at { Time.now }

    factory :v12_subscription do
      v12_plan
    end
  end
end
