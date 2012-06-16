FactoryGirl.define do
  factory :box_host do
    region
    sequence(:name) { |n| "box-host-#{n}" }
    sequence(:host) { |n| "box-host-#{n}.action.io" }
  end
end
