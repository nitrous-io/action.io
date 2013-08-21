require 'spec_helper'
require 'ostruct'

describe BillingProfile do
  it { should allow_mass_assignment_of :stripe_token }
  it { should belong_to(:user) }

  describe 'after_save callback' do
    let!(:stripe_token) { "stripe_token" }
    let!(:user) { create :user }
    let!(:billing_profile) { create :billing_profile, user: user }

    before do
      billing_profile.stripe_token = stripe_token
    end

    it 'calls StripeCustomerProfileJob with profile id, user email, description and stripe token' do
      StripeCustomerProfileJob.should_receive(:submit_job).with(billing_profile.id, user.email, "#{user.username} #{user.email}", stripe_token)
      billing_profile.save
    end

    it 'clears the stripe token' do
      billing_profile.save
      expect(billing_profile.stripe_token).to be_nil
    end
  end
end
