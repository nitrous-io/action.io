FactoryGirl.define do
  factory :billing_profile do
    association :user, factory: :user

    after(:build) { |billing_profile| billing_profile.class.skip_callback(:save, :before, :create_or_update_stripe_customer) }
  end
end
