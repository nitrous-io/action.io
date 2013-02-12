FactoryGirl.define do
  factory :box do
    sequence(:name) { |n| "box#{n}" }
    region
    host 'rikidozan-apne-1.action.io'
    sequence(:port) { |n| "12%03d" % n }
    state 'born'
    box_template
    association :owner, factory: :user
  end
end

# == Schema Information
#
# Table name: boxes
#
#  id              :integer          not null, primary key
#  name            :string(255)      not null
#  host            :string(255)
#  state           :string(255)      default("born"), not null
#  box_template_id :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  owner_id        :integer
#  region_id       :integer
#  port            :integer
#  terminated_at   :datetime
#

