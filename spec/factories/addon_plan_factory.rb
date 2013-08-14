FactoryGirl.define do
  factory :addon_plan do
    addon
    sequence(:name) {|n| "plan#{n}" }
    sequence(:price) {|n| n }
  end
end
