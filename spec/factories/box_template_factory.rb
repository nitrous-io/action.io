FactoryGirl.define do
  factory :box_template do
    sequence(:name) { |n| "box-template-#{n}" }
    sequence(:description) { |n| "Box Template #{n}" }
    sequence(:runtime)  { |n| "runtime-#{n}" }

    admin false
  end
end
