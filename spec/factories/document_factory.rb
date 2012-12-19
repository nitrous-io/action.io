FactoryGirl.define do
  factory :document  do
    user
    box
    pathname 'test.txt'
  end
end
