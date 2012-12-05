FactoryGirl.define do
  factory :document  do
    user
    box
    path 'test.txt'
    content 'whatsup'
    dirty false
  end
end
