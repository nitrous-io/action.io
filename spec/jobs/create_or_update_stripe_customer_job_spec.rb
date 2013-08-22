require 'spec_helper'

shared_examples_for 'an instance that retrieves and stores values from Stripe' do
  before do
    CreateOrUpdateStripeCustomerJob.new(billing_profile.id, user.email, description, stripe_token, plan.try(:id)).perform
  end

  it 'should retrieve and store the last four digits of the active credit card in Stripe' do
    expect(billing_profile.reload.last_four).to eq(stripe_customer.cards.data.first.last4)
  end

  it 'should retrieve and store the card type of the active credit card in Stripe' do
    expect(billing_profile.reload.card_type).to eq(stripe_customer.cards.data.first.type)
  end

  it 'should retrieve and store the expiry month of the active credit card in Stripe' do
    expect(billing_profile.reload.exp_month).to eq(stripe_customer.cards.data.first.exp_month)
  end

  it 'should retrieve and store the expiry year of the active credit card in Stripe' do
    expect(billing_profile.reload.exp_year).to eq(stripe_customer.cards.data.first.exp_year)
  end

  it 'should retrieve and store the id of the customer in Stripe' do
    expect(billing_profile.reload.stripe_id).to eq(stripe_customer.id)
  end
end

describe CreateOrUpdateStripeCustomerJob do
  describe '#perform' do
    let!(:user) { create :user }

    let!(:stripe_customer) { OpenStruct.new(id: 'id_01',
                                            cards: OpenStruct.new(
                                              data: [ OpenStruct.new(last4: '1234', type: 'Visa', exp_month: 10, exp_year: 2014 ) ]
                                            ))
                           }

    let!(:description) { "description" }
    let!(:stripe_token) { "stripe_token" }
    let!(:plan) { create :subscription_plan }

    context 'when a billing profile contains a stripe id' do
      let!(:billing_profile) { create :billing_profile, user: user, stripe_id: "stripe_id" }

      before do
        Stripe::Customer.should_receive(:retrieve).with(billing_profile.stripe_id) { stripe_customer }
      end

      it 'sets the card if stripe token is present' do
        stripe_customer.should_receive(:card=).with(stripe_token)
        CreateOrUpdateStripeCustomerJob.new(billing_profile.id, user.email, description, stripe_token, nil).perform
      end

      it 'sets customer email in Stripe' do
        stripe_customer.should_receive(:email=).with(user.email)
        CreateOrUpdateStripeCustomerJob.new(billing_profile.id, user.email, description, stripe_token, nil).perform
      end

      it 'sets the description in Stripe' do
        stripe_customer.should_receive(:description=).with(description)
        CreateOrUpdateStripeCustomerJob.new(billing_profile.id, user.email, description, stripe_token, nil).perform
      end

      it 'should save the changes in Stripe customer' do
        stripe_customer.should_receive(:save)
        CreateOrUpdateStripeCustomerJob.new(billing_profile.id, user.email, description, stripe_token, nil).perform
      end

      it_behaves_like 'an instance that retrieves and stores values from Stripe'
    end

    context 'when a billing profile doesnt contain a stripe id but has a stripe token' do
      let!(:billing_profile) { create :billing_profile, user: user }

      before do
        Stripe::Customer.should_receive(:create).with(
          email: user.email,
          description: description,
          card: stripe_token,
          plan: plan.stripe_id
        ).and_return stripe_customer
      end

      it 'creates a new customer in Stripe' do
        CreateOrUpdateStripeCustomerJob.new(billing_profile.id, user.email, description, stripe_token, plan.id).perform
      end

      it_behaves_like 'an instance that retrieves and stores values from Stripe'
    end

    context 'when a billing profile doesnt contain a stripe id or a stripe token' do
      let!(:billing_profile) { create :billing_profile, user: user }

      it 'logs a message' do
        Rails.logger.should_receive(:info)
        CreateOrUpdateStripeCustomerJob.new(billing_profile.id, user.email, description, nil, nil).perform
      end
    end
  end

  describe ".submit_job" do
    let!(:email) { 'some@exmaple.com' }
    let!(:description) { 'someuser some@example.com' }
    let!(:stripe_token) { 'stripe_token' }
    let!(:plan_id) { 1 }

    it "should submit a delayed job" do
      expect {
        CreateOrUpdateStripeCustomerJob.submit_job(1, email, description, stripe_token, plan_id)
      }.to change(Delayed::Job, :count).by(1)

      job_handler = Delayed::Job.all[-1].handler

      expect(job_handler).to match /CreateOrUpdateStripeCustomerJob.*?profile_id: 1/m
      expect(job_handler).to match /CreateOrUpdateStripeCustomerJob.*?email: #{email}/m
      expect(job_handler).to match /CreateOrUpdateStripeCustomerJob.*?description: #{description}/m
      expect(job_handler).to match /CreateOrUpdateStripeCustomerJob.*?stripe_token: #{stripe_token}/m
      expect(job_handler).to match /CreateOrUpdateStripeCustomerJob.*?plan_id: #{plan_id}/m
    end
  end
end


