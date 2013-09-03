require 'spec_helper'

describe BillingProfileSerializer do
  let!(:subscription_plan) { create :subscription_plan }
  let!(:billing_profile) { create :billing_profile, plan: subscription_plan }
  let!(:subscription) { create :subscription, state: 'active', billing_profile: billing_profile }

  subject { billing_profile.serialize_as_json }

  it 'has only formatted_card_number, card_type and active_subscription' do
    hash = JSON.parse(subject)['billing_profile']
    hash.delete('formatted_card_number' ).should == billing_profile.formatted_card_number
    hash.delete('card_type'             ).should == billing_profile.card_type
    hash.delete('subscriptions'         ).should == [JSON.parse(subscription.serialize_as_json)['subscription']]
    hash.should be_empty
  end
end
