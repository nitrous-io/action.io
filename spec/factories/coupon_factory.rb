FactoryGirl.define do
  factory :coupon do
    sequence(:code)           { |n| "coupon-#{n}" }
    sequence(:duration)       { |n| n }
    sequence(:percent_off)    { |n| n * 10 }

    after(:build) do |coupon|
      coupon.class.skip_callback(:create, :before, :create_in_stripe)
    end

    factory :coupon_with_callbacks do
      after(:build) do |coupon|
        coupon.class.set_callback(:create, :before, :create_in_stripe)
      end
    end

  end
end
