require 'spec_helper'

describe Coupon do
  it { should allow_mass_assignment_of :code }
  it { should allow_mass_assignment_of :duration }
  it { should allow_mass_assignment_of :percent_off }
  it { should allow_mass_assignment_of :active }

  it { should have_many(:billing_profiles) }

  it { should validate_presence_of :code }
  it { should validate_numericality_of :percent_off }
  it { should validate_numericality_of :duration }

  describe 'scopes' do
    describe '.enabled' do
      let!(:coupon1) { create :coupon, active: true }
      let!(:coupon2) { create :coupon, active: true }
      let!(:coupon3) { create :coupon, active: false }

      subject { Coupon.active.all }

      it { should == [coupon1, coupon2] }
    end
  end

end
