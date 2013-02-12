require 'spec_helper'

describe BoxAdmin do
  it { should belong_to :box }
  it { should belong_to :user }

  it { should_not allow_mass_assignment_of :box_id }
  it { should_not allow_mass_assignment_of :user_id }
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
