require 'spec_helper'
require 'ostruct'

shared_examples_for "an instance that retrives and store data from Stripe" do

  before do
    Stripe::Customer.stub(:create) { stripe_customer }
    billing_profile.save
  end

  it 'should retrieve and store the last four digits of the active credit card in Stripe' do
    expect(billing_profile.reload.last_four).to eq('1234')
  end

  it 'should retrieve and store the card type of the active credit card in Stripe' do
    expect(billing_profile.reload.card_type).to eq('Visa')
  end
end

shared_examples_for "an instance that set the stripe id and clear the stripe token" do
  before do
    stripe_customer.stub(:save)
    Stripe::Customer.stub(:create) { stripe_customer }

    billing_profile.save
  end

  it 'should set the stripe id' do
    expect(billing_profile.reload.stripe_id).to eq(stripe_customer.id)
  end

  it 'should clear the stripe token' do
    expect(billing_profile.reload.stripe_token).to be_nil
  end
end

describe BillingProfile do
  it { should allow_mass_assignment_of :stripe_token }
  it { should belong_to(:user) }

  describe '#save' do
    let!(:user) { create :user }
    let!(:stripe_customer) { OpenStruct.new(id: 'id_01', active_card: OpenStruct.new(last4: '1234', type: 'Visa' )) }
    let!(:stripe_token) { "stripe_token" }

    context 'when theres no stripe id associated with the profile' do
      let!(:billing_profile) { build :billing_profile, user: user }

      context 'when no stripe token is present' do
        it 'should raise an error' do
          expect {
            billing_profile.save
          }.to raise_error
        end
      end

      context 'when a stripe token is present' do
        before do
          billing_profile.stripe_token = stripe_token
        end

        it 'should create a new customer in Stripe' do
          Stripe::Customer.should_receive(:create).with(
            email: user.email,
            description: "#{user.username} #{user.email}",
            card: stripe_token
          ).and_return stripe_customer

          billing_profile.save
        end

        it_behaves_like "an instance that retrives and store data from Stripe"
        it_behaves_like "an instance that set the stripe id and clear the stripe token"
      end
    end

    context 'when a stripe id is already assoicated with the profile' do
      let!(:billing_profile) { build :billing_profile, user: user, stripe_id: 'id_0001' }

      before do
        billing_profile.stripe_token = stripe_token

        Stripe::Customer.should_receive(:retrieve).with(billing_profile.stripe_id) { stripe_customer }
      end

      it 'sets the stripe token if present' do
        stripe_customer.should_receive(:card=).with(stripe_token)
        billing_profile.save
      end

      it 'sets customer email in Stripe' do
        stripe_customer.should_receive(:email=).with(user.email)
        billing_profile.save
      end

      it 'sets the description in Stripe' do
        stripe_customer.should_receive(:description=).with("#{user.username} #{user.email}")
        billing_profile.save
      end

      it 'should save the changes in Stripe customer' do
        stripe_customer.should_receive(:save)
        billing_profile.save
      end

      it_behaves_like "an instance that retrives and store data from Stripe"
      it_behaves_like "an instance that set the stripe id and clear the stripe token"
    end
  end
end
