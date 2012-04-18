FactoryGirl.define do
  factory :box do
    sequence(:name) { |n| "box#{n}" }
    region
    host 'alpha.us-east-1.action.io'
    sequence(:port) { |n| "22%02d" % n }
    state 'provisioning'
    box_template
    association :owner, factory: :user
  end
end
