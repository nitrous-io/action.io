require 'spec_helper'

describe Coupon do
  it { should allow_mass_assignment_of :code }
  it { should allow_mass_assignment_of :duration }
  it { should allow_mass_assignment_of :percent_off }
  it { should allow_mass_assignment_of :active }
  it { should allow_mass_assignment_of :description }

  it { should validate_presence_of :code }
  it { should validate_numericality_of :percent_off }
  it { should validate_numericality_of :duration }

  describe 'scopes' do
    describe '.active' do
      let!(:coupon1) { create :coupon, active: true }
      let!(:coupon2) { create :coupon, active: true }
      let!(:coupon3) { create :coupon, active: false }

      subject { Coupon.active.all }

      it { should == [coupon1, coupon2] }
    end
  end

  describe '.generate' do
    it 'should send a request to Stripe to create the coupon' do
      Stripe::Coupon.should_receive(:create).with({
        id: 'OSOMPROMO',
        percent_off: 100,
        duration: 'repeating',
        duration_in_months: 12
      })

      coupon = Coupon.generate({
        code: 'OSOMPROMO',
        percent_off: 100,
        duration: 12
      })

      expect(coupon.persisted?).to be_true
      expect(coupon.code).to eq('OSOMPROMO')
    end

    context 'when there is a Stripe::APIConnectionError' do
      before { Stripe::Coupon.stub(:create).and_raise(Stripe::APIConnectionError) }

      it 'should add an error and should not save the coupon' do
        coupon = Coupon.generate({
          code: 'OSOMPROMO',
          percent_off: 100,
          duration: 12
        })

        expect(coupon.errors.messages).to include(:base)
        expect(coupon.persisted?).to be_false
      end
    end

    context 'when there is a Stripe::StripeError' do
      before { Stripe::Coupon.stub(:create).and_raise(Stripe::APIConnectionError) }

      it 'should add an error and should not save the coupon' do
        coupon = Coupon.generate({
          code: 'OSOMPROMO',
          percent_off: 100,
          duration: 12
        })

        expect(coupon.errors.messages).to include(:base)
        expect(coupon.persisted?).to be_false
      end
    end
  end

end
