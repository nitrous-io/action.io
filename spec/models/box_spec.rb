# coding: utf-8

require 'spec_helper'

describe Box do
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :region }
  it { should_not allow_mass_assignment_of :host }
  it { should_not allow_mass_assignment_of :port }
  it { should_not allow_mass_assignment_of :status }
  it { should_not allow_mass_assignment_of :template_id }

  it { should have_many(:box_admins).dependent(:destroy) }
  it { should have_many(:users).through(:box_admins) }
  it { should belong_to(:box_template) }
  it { should belong_to(:owner).class_name('User') }

  describe 'validations' do
    let!(:box) { create :box }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:region) }

    it { should validate_uniqueness_of(:name) }

    it { should allow_value(*Settings.valid_regions).for(:region) }
    it { should_not allow_value('china').for(:region) }

    it { should allow_value('fragrant-wind-69').for(:name) }
    it { should allow_value('fragrantwind69').for(:name) }
    it { should_not allow_value('fr@gr@nt-w|nd-69').for(:name) }
    it { should_not allow_value('fragrant_wind_69').for(:name) }
    it { should_not allow_value('69-fragrant-wind').for(:name) }
    it { should_not allow_value('-fragrant-wind-69').for(:name) }
    it { should_not allow_value('fragrant-wind-69-').for(:name) }
    it { should_not allow_value('fragrant wind 69').for(:name) }
    it { should_not allow_value('향기로운-바람-69').for(:name) }

    it 'validates presence of owner only when box is a new record' do
       box.owner = nil
       box.should be_valid
       new_box = build :box, owner: nil
       new_box.should_not be_valid
    end
  end

  it 'downcases name before saving' do
    box = build :box, name: 'Fragrant-Wind-69'
    box.save
    box.name.should == 'fragrant-wind-69'
  end

  it 'adds owner to users on create' do
    user = create :user
    box = create :box, owner: user
    box.users.should == [user]
  end
end
