require 'spec_helper'
require 'ostruct'

describe BillingProfile do
  it { should belong_to(:user) }
  it { should have_many(:receipts).dependent(:destroy) }

  describe '#expiry' do
    let!(:billing_profile) { create :billing_profile }

    it 'returns a expiry date consisting of the expiry month and year' do
      billing_profile.exp_month = 12
      billing_profile.exp_year = 2013

      expect(billing_profile.expiry).to eq('12/2013')
    end
  end

  describe '#formatted_card_number' do
    let!(:billing_profile) { create :billing_profile }

    it 'returns a formatted card number including the last four digits of the card' do
      billing_profile.last_four = 4422

      expect(billing_profile.formatted_card_number).to eq('#############4422')
    end
  end

  describe '.find_profiles_with_expiring_cards' do
    let!(:billing_profile_1) { create :billing_profile, exp_month: 9, exp_year: 2013 }
    let!(:billing_profile_2) { create :billing_profile, exp_month: 9, exp_year: 2013 }
    let!(:billing_profile_3) { create :billing_profile, exp_month: 11, exp_year: 2013 }

    let!(:subscription_1) { create :subscription, state: 'active', user: billing_profile_1.user }
    let!(:subscription_2) { create :subscription, state: 'canceled', user: billing_profile_2.user }
    let!(:subscription_3) { create :subscription, state: 'active', user: billing_profile_3.user }

    context 'when a valid date is provided' do
      it 'returns only the profiles of users having active subscriptions which are expiring in the given month' do
        date = Time.utc(2013, 9)
        expect(BillingProfile.find_profiles_with_expiring_cards(date)).to eq [billing_profile_1]
      end
    end

    context 'when the date is nil' do
      it 'should not return any profiles' do
        expect(BillingProfile.find_profiles_with_expiring_cards(nil)).to eq nil
      end
    end
  end

end
