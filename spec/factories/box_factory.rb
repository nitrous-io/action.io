FactoryGirl.define do
  factory :box do
    sequence(:name) { |n| "box#{n}" }
    region 'us-east-1'
    host 'alpha.us-east-1.action.io'
    sequence(:port) { |n| "22%02d" % n }
    status 'new'
    template
  end
end
