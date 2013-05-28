FactoryGirl.define do
  factory :plan do
    sequence(:name) { |n| "plan#{n}" }
    num_boxes 1
    active true

    factory :v12_plan do
      num_boxes 5
    end
  end
end
