FactoryGirl.define do
  factory :box_template do
    sequence(:name) { |n| "box-template-#{n}" }
    sequence(:image) { |n| "boxtemplate#{n}" }
    sequence(:description) { |n| "Box Template #{n}" }
  end
end
