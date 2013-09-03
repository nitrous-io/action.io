FactoryGirl.define do
  factory :box do
    sequence(:name) { |n| "box#{n}" }
    host 'rikidozan-apne-1.nitrous.io'
    sequence(:port) { |n| "12%03d" % n }
    state 'born'
    box_template
    association :owner, factory: :user
    association :region, enabled: true
    version 'bran'
  end
end
