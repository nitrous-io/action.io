FactoryGirl.define do
  factory :refund do
    amount            1000
    stripe_charge_id  "ch_0001"
    association       :user
  end
end
