FactoryGirl.define do
  factory :boxhost do
    sequence(:name) { |n| "boxhost-#{n}" }
  end

  factory :dedicated_boxhost, class: 'DedicatedBoxhost' do
    sequence(:name) { |n| "boxhost-#{n}" }
    type 'DedicatedBoxhost'
    association :owner, factory: :user
  end
end
