FactoryGirl.define do
  factory :box do
    sequence(:name) { |n| "box#{n}" }
    region
    host 'rikidozan-apne-1.action.io'
    sequence(:port) { |n| "12%03d" % n }
    state 'provisioning'
    box_template
    association :owner, factory: :user_with_invite
  end
end
