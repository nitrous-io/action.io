FactoryGirl.define do
  factory :document  do
    user
    box
    pathname 'test.txt'
    content 'whatsup'
    clean true
  end
end
