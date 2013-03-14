FactoryGirl.define do
  factory :doorkeeper_application, class: Doorkeeper::Application do
    sequence(:name) { |n| "app#{n}" }
    sequence(:redirect_uri) { |n| "http://example.com/#{n}" }
  end
end
