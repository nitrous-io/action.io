FactoryGirl.define do
  factory :boxhost_plan do
    sequence(:name) { |n| "#{n}x" }
    sequence(:price) { |n| n * 100 }
    interval 'month'
    box_limit 1
  end
end
