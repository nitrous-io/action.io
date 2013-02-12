FactoryGirl.define do
  factory :region do
    sequence(:name)           { |n| "region-#{n}" }
    sequence(:description)    { |n| "Region #{n}" }
    sequence(:box_server_uri) { |n| "https://box-server-uri-#{n}" }
    sequence(:coach_uri)      { |n| "https://coach-#{n}" }
  end
end

# == Schema Information
#
# Table name: regions
#
#  id             :integer          not null, primary key
#  name           :string(255)      not null
#  description    :string(255)      not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  enabled        :boolean          default(FALSE), not null
#  box_server_uri :string(255)
#  coach_uri      :string(255)
#

