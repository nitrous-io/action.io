FactoryGirl.define do
  factory :key_pair do
    sequence(:private_key)  { |n| "private-key-#{n}" }
    sequence(:public_key)   { |n| "public-key-#{n}" }
    box
  end
end

# == Schema Information
#
# Table name: key_pairs
#
#  id                       :integer          not null, primary key
#  box_id                   :integer          not null
#  public_key               :text             not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  encrypted_private_key    :text             not null
#  encrypted_private_key_iv :string(255)      not null
#
