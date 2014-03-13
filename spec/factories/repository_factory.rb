FactoryGirl.define do
  factory :repository do
    sequence(:name) { |n| "repository#{n}" }
    sequence(:clone_url) { |n| "https://github.com/nitrous-io/project-#{n}.git" }
    association :box, factory: :box
  end
end
