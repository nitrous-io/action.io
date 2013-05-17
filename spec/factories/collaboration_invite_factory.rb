FactoryGirl.define do
  factory :collaboration_invite do
    sequence(:email) { |n| "collaboration_invite#{n}@example.com" }
    box
    state 'activated'
  end
end

