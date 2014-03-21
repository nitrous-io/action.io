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

  describe '.with_expiring_cards' do
    let!(:billing_profile_1) { create :billing_profile, exp_month: 9, exp_year: 2013 }
    let!(:billing_profile_2) { create :billing_profile, exp_month: 9, exp_year: 2013 }
    let!(:billing_profile_3) { create :billing_profile, exp_month: 11, exp_year: 2013 }

    let!(:subscription_1) { create :subscription, state: 'active', user: billing_profile_1.user }
    let!(:subscription_2) { create :subscription, state: 'canceled', user: billing_profile_2.user }
    let!(:subscription_3) { create :subscription, state: 'active', user: billing_profile_3.user }

    context 'when a valid date is provided' do
      it 'returns only the profiles of users having active subscriptions which are expiring in the given month' do
        date = Time.utc(2013, 9)
        expect(BillingProfile.with_expiring_cards(date).to_a).to eq [billing_profile_1]
      end
    end
  end

  describe '.needs_expiration_alert' do
    let!(:billing_profile_1) { create :billing_profile, exp_month: 9, exp_year: 2013 }
    let!(:billing_profile_2) { create :billing_profile, exp_month: 9, exp_year: 2013 }
    let!(:billing_profile_3) { create :billing_profile, exp_month: 11, exp_year: 2013 }
    let!(:billing_profile_4) { create :billing_profile, exp_month: 9, exp_year: 2013 }
    let!(:billing_profile_5) { create :billing_profile, exp_month: 9, exp_year: 2013 }

    let!(:subscription_1) { create :subscription, state: 'active', user: billing_profile_1.user }
    let!(:subscription_2) { create :subscription, state: 'canceled', user: billing_profile_2.user }
    let!(:subscription_3) { create :subscription, state: 'active', user: billing_profile_3.user }
    let!(:subscription_4) { create :subscription, state: 'active', user: billing_profile_4.user }
    let!(:subscription_5) { create :subscription, state: 'active', user: billing_profile_5.user }

    before do
      Timecop.freeze(Time.now) do
        billing_profile_4.update_attribute :expiration_notice_sent_at, 15.days.ago
        billing_profile_5.update_attribute :expiration_notice_sent_at, 13.days.ago
      end
    end

    after { Timecop.return }

    it 'returns only the profiles of users having active subscriptions which are expiring in the given month' do
      date = Time.utc(2013, 9)
      expect(BillingProfile.needs_expiration_alert(date).to_a).to match_array [billing_profile_1, billing_profile_4]
    end

  end

end
