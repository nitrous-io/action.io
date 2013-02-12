FactoryGirl.define do
  factory :authentication do
    association :user, factory: :user
    provider 'github'
    sequence(:uid) { |n| "#{n}" }
    sequence(:token) { |n| "someToken#{n}" }
  end
end

# == Schema Information
#
# Table name: authentications
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  provider   :string(255)      not null
#  uid        :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  token      :string(255)
#
