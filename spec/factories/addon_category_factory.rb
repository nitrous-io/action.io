FactoryGirl.define do
  factory :addon_category do
    sequence(:name) { |n| "category-#{n}" }
    sequence(:icon) { |n| "icon-#{n}" }
  end
end

