FactoryGirl.define do
  factory :box_template do
    sequence(:name) { |n| "box-template-#{n}" }
    sequence(:description) { |n| "Box Template #{n}" }
    sequence(:runtime)  { |n| "runtime-#{n}" }

    admin false
  end
end

# == Schema Information
#
# Table name: box_templates
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  description :text             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  enabled     :boolean          default(FALSE), not null
#  runtime     :string(255)
#  admin       :boolean          default(FALSE), not null
#
