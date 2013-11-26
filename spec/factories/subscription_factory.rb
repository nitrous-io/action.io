FactoryGirl.define do
  factory :subscription do
    plan { create :subscription_plan }
    billing_profile   { create :billing_profile }
  end
end
