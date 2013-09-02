FactoryGirl.define do
  factory :billing_profile do
    association :user, factory: :user
    stripe_id 'cus_0001'

    after(:build) { |billing_profile| billing_profile.class.skip_callback(:save, :before, :create_or_update_stripe_customer) }

    factory :billing_profile_with_callbacks do
      after(:build) { |billing_profile| billing_profile.class.set_callback(:save, :before, :create_or_update_stripe_customer) }
    end
  end
end
