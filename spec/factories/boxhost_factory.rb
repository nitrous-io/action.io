FactoryGirl.define do
  factory :boxhost, class: 'FreeBoxhost' do
    sequence(:name) { |n| "freeboxhost-#{n}" }
    type 'FreeBoxhost'
    association :region, factory: :region, enabled: true
  end

  factory :dedicated_boxhost, class: 'DedicatedBoxhost' do
    sequence(:name) { |n| "dedicatedboxhost-#{n}" }
    type 'DedicatedBoxhost'
    association :owner, factory: :user
    association :region, factory: :region, enabled: true
  end
end
