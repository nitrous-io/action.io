FactoryGirl.define do
  factory :boxhost do
    sequence(:name) { |n| "boxhost-#{n}" }
    association :region, enabled: true
    type 'FreeBoxhost'
  end

  factory :dedicated_boxhost, parent: :boxhost, class: 'DedicatedBoxhost' do
    type 'DedicatedBoxhost'
    association :owner, factory: :user
  end
end
