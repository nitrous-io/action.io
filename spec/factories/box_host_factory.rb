FactoryGirl.define do
  factory :box_host do
    region
    name { Faker::Name.first_name }
    sequence(:host) { |n| "box-host-#{n}.action.io" }
  end
end
