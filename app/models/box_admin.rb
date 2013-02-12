class BoxAdmin < ActiveRecord::Base
  belongs_to :box
  belongs_to :user

  attr_accessible
end

# == Schema Information
#
# Table name: box_admins
#
#  id         :integer          not null, primary key
#  box_id     :integer          not null
#  user_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
