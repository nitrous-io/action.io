FactoryGirl.define do
  factory :region do
    sequence(:name)           { |n| "region-#{n}" }
    sequence(:label)           { |n| "region-#{n}" }
    sequence(:description)    { |n| "Region #{n}" }
    sequence(:box_server_uri) { |n| "https://box-server-uri-#{n}" }
    sequence(:coach_uri)      { |n| "https://coach-#{n}" }
  end
end
