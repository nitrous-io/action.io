require 'spec_helper'

describe Refund do
  it { should belong_to :user }

  it { should allow_mass_assignment_of :user_id }
  it { should allow_mass_assignment_of :stripe_charge_id }
  it { should allow_mass_assignment_of :amount }
  it { should allow_mass_assignment_of :reason }

  it { should validate_presence_of :amount_in_cents }
  it { should validate_presence_of :stripe_charge_id }
  it { should validate_numericality_of :amount_in_cents }

  describe '#amount' do
    let!(:refund) { build :refund }

    before do
      refund.amount_in_cents = 1095
    end

    it 'returns the amount as a currrency value' do
      expect(refund.amount).to eq(10.95)
    end
  end

  describe '#amount=' do
    let!(:refund) { build :refund }

    it 'accepts a currency value and stores it as cents' do
      refund.amount = 19.99
      expect(refund.amount_in_cents).to eq(1999)
    end
  end

  describe 'process!' do
    let!(:refund) { build :refund, stripe_charge_id: 'ch_001', amount_in_cents: 1095 }
    let!(:stripe_charge) { double 'Stripe::Charge' }

    context 'when the refund is valid' do
      it 'sends a request to Stripe to refund the given amount for the given charge and then mark the refund as processed' do
        expect(Stripe::Charge).to receive(:retrieve).with('ch_001').and_return stripe_charge
        expect(stripe_charge).to receive(:refund).with(amount: 1095).and_return true

        refund.process!
        expect(refund.reload.processed_at).to_not be_nil
      end
    end

    context 'when the refund is invalid' do
      before do
        refund.amount = nil
        refund.stripe_charge_id = nil
      end

      it 'does not send a request to Stripe to refund the charge' do
        expect(Stripe::Charge).to_not receive(:retrieve)
        refund.process!
      end
    end

    context 'when the refund is already processed' do
      before do
        refund.processed_at = Time.now
      end

      it 'does not send a request to Stripe to refund the charge' do
        expect(Stripe::Charge).to_not receive(:retrieve)
        refund.process!
      end
    end

    context 'when there is a Stripe::APIConnectionError' do
      before { Stripe::Charge.stub(:retrieve).and_raise(Stripe::APIConnectionError) }

      it 'should add an error and should not save the refund' do
        refund.process!

        expect(refund.errors.messages).to include(:base)
        expect(refund.persisted?).to be_falsey
      end
    end

    context 'when there is a Stripe::StripeError' do
      before { Stripe::Charge.stub(:retrieve).and_raise(Stripe::StripeError) }

      it 'should add an error and should not save the refund' do
        refund.process!

        expect(refund.errors.messages).to include(:base)
        expect(refund.persisted?).to be_falsey
      end
    end
  end
end
