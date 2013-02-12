FactoryGirl.define do
  factory :snapshot do
    sequence(:name) { |n| "box#{n}" }
    description 'some snapshot'
    public false
    association :owner, factory: :user
    association :box, factory: :box
  end
end

# == Schema Information
#
# Table name: snapshots
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  description :string(255)
#  public      :boolean
#  box_id      :integer
#  owner_id    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
