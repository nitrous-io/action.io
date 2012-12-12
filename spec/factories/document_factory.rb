FactoryGirl.define do
  factory :document  do
    user
    box
    pathname 'test.txt'
    content 'whatsup'
    last_saved_content 'whatsup'
  end
end
