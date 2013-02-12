FactoryGirl.define do
  factory :user do
    sequence(:username)  { |n| "user#{n}" }
    sequence(:email)     { |n| "user#{n}@example.com" }
    sequence(:full_name) { |n| "User #{n}" }
    password '123456'
    password_confirmation '123456'

    ignore do
      invite_code nil
    end

    factory :admin do
      admin true
    end

    after(:build) do |user, evaluator|
      unless user.admin?
        user.invite_code = evaluator.invite_code || Digest::SHA1.hexdigest("#{user.email}-#{Time.now.to_i}")[0...7]
        FactoryGirl.create(:invite, invite_code: user.invite_code, email: user.email, state: 'activated')
      end
    end
  end
end

# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  username               :string(255)      not null
#  encrypted_password     :string(255)
#  email                  :string(255)      not null
#  full_name              :string(255)
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  authentication_token   :string(255)
#  invite_code            :string(255)
#  admin                  :boolean          default(FALSE), not null
#  available_invites      :integer          default(0), not null
#

