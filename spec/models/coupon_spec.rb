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

  describe '#create' do
    let!(:coupon) { build :coupon_with_callbacks }

    context 'creates a coupon on stripe end' do
      before do
        Stripe::Coupon.should_receive(:create).with(
          id: coupon.code,
          percent_off: coupon.percent_off,
          duration: 'repeating',
          duration_in_months: coupon.duration
        )
      end

      it 'saves the coupon' do
        expect {
          coupon.save
        }.to change { Coupon.count }.by 1
      end
    end

    context 'failes to create a coupon on stripe end' do
      before do
        Stripe::Coupon.stub(:create).and_raise Stripe::StripeError.new(nil, nil, nil, { error: { code: '', message: 'stripe error' }})
      end

      it 'does not save the coupon' do
        expect {
          coupon.save
        }.to_not change { Coupon.count }
      end
    end
  end

  describe 'scopes' do
    describe '.enabled' do
      let!(:coupon1) { create :coupon, active: true }
      let!(:coupon2) { create :coupon, active: true }
      let!(:coupon3) { create :coupon }

      subject { Coupon.active.all }

      it { should == [coupon1, coupon2] }
    end
  end

end
