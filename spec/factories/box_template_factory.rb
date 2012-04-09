FactoryGirl.define do
  factory :box_template do
    sequence(:name) { |n| "ubuntu-rails-#{n}" }
    image 'ubuntu-ruby-rails'
    description 'Ubuntu + Ruby + Rails'
  end
end
