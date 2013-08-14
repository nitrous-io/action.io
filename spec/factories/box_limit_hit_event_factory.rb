FactoryGirl.define do
  factory :box_limit_hit_event do
    sequence(:kind)             { |n| "kind-#{n}" }
    sequence(:logged_event_id)  { |n| "event-id-#{n}" }
    sequence(:limit_hit_at)     { |n| Time.now + n }

    association :box
  end
end
