FactoryGirl.define do
  factory :box do
    sequence(:name) { |n| "box#{n}" }
    region
    host 'rikidozan-apne-1.action.io'
    sequence(:port) { |n| "12%03d" % n }
    state 'provisioning'
    sequence(:ip)               { |n| "192.168.254.#{n}" }
    sequence(:block_device_id)  { |n| "z#{n}" }
    box_template
    association :owner, factory: :user
  end
end
