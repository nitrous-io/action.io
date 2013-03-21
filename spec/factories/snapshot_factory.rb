FactoryGirl.define do
  factory :snapshot do
    sequence(:name) { |n| "box#{n}" }
    description 'some snapshot'
    public false
    association :box, factory: :box
  end
end
