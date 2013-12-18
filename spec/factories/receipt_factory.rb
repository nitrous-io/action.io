FactoryGirl.define do
  factory :receipt do
    subtotal        500
    total           500

    association     :billing_profile
  end
end
