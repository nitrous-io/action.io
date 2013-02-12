# coding: utf-8

require 'spec_helper'

describe Box do
  it { should allow_mass_assignment_of :name }
  it { should_not allow_mass_assignment_of :host }
  it { should_not allow_mass_assignment_of :port }
  it { should_not allow_mass_assignment_of :tty_port }
  it { should_not allow_mass_assignment_of :state }
  it { should_not allow_mass_assignment_of :key }
  it { should_not allow_mass_assignment_of :box_template_id }
  it { should_not allow_mass_assignment_of :owner_id }
  it { should_not allow_mass_assignment_of :region_id }

  it { should have_many(:box_admins).dependent(:destroy) }
  it { should have_many(:key_pairs).dependent(:destroy) }

  it { should have_many(:users).through(:box_admins) }
  it { should belong_to(:box_template) }
  it { should belong_to(:owner).class_name('User') }
  it { should belong_to(:region) }


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

