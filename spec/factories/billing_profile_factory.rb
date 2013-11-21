FactoryGirl.define do
  factory :billing_profile do
    association :user
    sequence(:stripe_id)           { |n| "cus-#{n}" }
    plan { create :subscription_plan }

    last_four "1234"
    card_type "Visa"
    exp_month 9
    exp_year  2013

    after(:build) do |billing_profile|
      billing_profile.class.skip_callback(:save, :before, :create_or_update_stripe_customer)
      billing_profile.class.skip_callback(:save, :before, :change_plan)
      billing_profile.class.skip_callback(:save, :after,  :push_billing_profile_updated_message)
    end

    factory :billing_profile_with_callbacks do
      after(:build) do |billing_profile|
        billing_profile.class.set_callback(:save, :before, :create_or_update_stripe_customer)
        billing_profile.class.set_callback(:save, :before, :change_plan)
        billing_profile.class.set_callback(:save, :after,  :push_billing_profile_updated_message)
      end
    end
  end
end
