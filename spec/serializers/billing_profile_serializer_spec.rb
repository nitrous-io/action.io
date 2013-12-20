require 'spec_helper'

describe BillingProfileSerializer do
  let!(:billing_profile) { create :billing_profile }

  subject { billing_profile.serialize_as_json }

  it 'has only formatted_card_number, card_type and active_subscription' do
    hash = JSON.parse(subject)['billing_profile']
    expect(hash.delete('id'                    )).to eq(billing_profile.id)
    expect(hash.delete('formatted_card_number' )).to eq(billing_profile.formatted_card_number)
    expect(hash.delete('card_type'             )).to eq(billing_profile.card_type)
    expect(hash).to be_empty
  end
end
