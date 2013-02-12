FactoryGirl.define do
  factory :invite do
    sequence(:email) { |n| "invite#{n}@example.com" }
    state 'pending'
  end
end

# == Schema Information
#
# Table name: invites
#
#  id               :integer          not null, primary key
#  email            :string(255)      not null
#  invite_code      :string(255)
#  state            :string(255)      default("pending"), not null
#  inviting_user_id :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  ip               :string(255)
#  city             :string(255)
#  country          :string(255)
#  country_code     :string(255)
#  latitude         :float
#  longitude        :float
#  referral_code    :string(255)
#  referrer_code    :string(255)
#  referred_visits  :integer          default(0), not null
#

