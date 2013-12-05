require 'spec_helper'

describe SubscriptionsController do
  let(:user) { create :user }
  let!(:fake_stripe_customer)  { double }

  describe 'POST create', focus: true do
    def do_request(params={})
      post :create, { format: 'json'}.merge(params)
    end

    context 'when signed in' do
      let!(:plan) { create :plan }
      let!(:stripe_token) { 'abcdefghighkl' }
      let!(:stripe_customer) do
        OpenStruct.new(
          id: 'id_01', cards: OpenStruct.new(
            data: [ OpenStruct.new(last4: '1234', type: 'Visa', exp_month: 10, exp_year: 2014 ) ]
          )
        )
      end
      let(:channel) { double.as_null_object }

      before do
        sign_in user
        Stripe::Customer.stub(:create) { fake_stripe_customer }
        Shover.stub(:publish)
        Pusher.stub(:[]).with("private-user-#{user.id}") { channel }
        channel.stub(:trigger)
      end

      context 'when both stripe_token and plan are provided' do
        before do
          Stripe::Customer.stub(:create) { fake_stripe_customer }

          fake_stripe_customer.stub_chain('cards.data.first.last4') { '1234' }
          fake_stripe_customer.stub_chain('cards.data.first.type') { 'visa' }
          fake_stripe_customer.stub_chain('cards.data.first.exp_month') { '12' }
          fake_stripe_customer.stub_chain('cards.data.first.exp_year') { '2014' }
          fake_stripe_customer.stub('id') { 'cus1234' }
        end

        it 'creates a new billing profile for the user' do
          expect {
            do_request({ plan_id: plan.id, stripe_token: stripe_token })
          }.to change { BillingProfile.count }.by 1

          billing_profile = BillingProfile.last
          expect(billing_profile.user).to eq(user)
        end

        it 'stores the stripe customer id for the user' do
          do_request({ plan_id: plan.id, stripe_token: stripe_token })
          expect(user.reload.stripe_customer_id).to eq('cus1234')
        end

        it 'responds with a created status' do
          do_request({ plan_id: plan.id, stripe_token: stripe_token })
          expect(controller).to respond_with :created
        end
      end

      context 'when stripe token is not provided' do
        it 'does not create a new billing profile for the user' do
          expect {
            do_request({ plan_id: plan.id, stripe_token: nil })
          }.not_to change { BillingProfile.count }.by 1
        end

        it 'does not store a stripe customer id for the user' do
          do_request({ plan_id: plan.id, stripe_token: nil })
          expect(user.reload.stripe_customer_id).to be_nil
        end

        it 'responds with a unprocessable_entity status' do
          do_request({ plan_id: plan.id, stripe_token: nil })
          expect(controller).to respond_with :unprocessable_entity
        end

        it 'respond body contains an error message' do
          do_request({ plan_id: plan.id, stripe_token: nil })
          expect(response.body).to eq({errors: { base: ['invalid request'] } }.to_json)
        end
      end

      context 'when subscription plan is not provided' do
        it 'raises record not found' do
          expect {
            do_request({ plan_id: nil, stripe_token: stripe_token })
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'PUT update' do
    let!(:billing_profile) { create :billing_profile, user: user }
    let!(:subscription) { create :subscription, state: 'active', billing_profile: billing_profile }

    def do_request(params={})
      put :update, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      let!(:stripe_token) { 'abcdefghighkl' }

      before do
        sign_in user

        fake_stripe_customer.stub(:card=)
        fake_stripe_customer.stub(:save)
        Stripe::Customer.stub(:retrieve) { fake_stripe_customer }

        allow_any_instance_of(BillingProfile).to receive(:push_billing_profile_updated_message)
      end

      context 'when only stripe token is provided' do
        context 'card is successfully stored in Stripe' do
          before do
            do_request({ stripe_token: stripe_token, plan_id: '' })
          end

          it { should respond_with :ok }
        end

        context 'Stripe declines the card' do
          before do
            fake_stripe_customer.should_receive(:save).and_raise Stripe::CardError.new('', '', '', nil, nil, { error: { code: 'card_declined', message: 'stripe error' }})
            do_request({stripe_token: stripe_token, plan_id: ''  })
          end

          it { should respond_with :unprocessable_entity }
          its('response.body') { should == { errors: { base: ['stripe error Try contacting your bank directly for assistance.'] } }.to_json }
        end
      end

      context 'user tries to change the subscription plan' do
        let!(:new_plan) { create :plan }

        context 'when subscription plan can be changed' do
          before do
            user.update_attribute 'max_n2o', 600
            user.update_attribute 'used_n2o', 100
            billing_profile.active_subscription.plan.update_attribute 'n2o_amount', 500
            new_plan.update_attribute 'n2o_amount', 200

            fake_stripe_customer.stub(:update_subscription)

            do_request({ stripe_token: stripe_token, plan_id: new_plan.id })
          end

          it { should respond_with :ok }
        end

        context 'when subscription plan cannot be changed' do
          before do
            user.update_attribute 'max_n2o', 600
            user.update_attribute 'used_n2o', 500
            billing_profile.active_subscription.plan.update_attribute 'n2o_amount', 500
            new_plan.update_attribute 'n2o_amount', 200

            do_request({ stripe_token: stripe_token, plan_id: new_plan.id })
          end

          it { should respond_with :unprocessable_entity }
          its('response.body') { should == { errors: { base: ['You need to terminate boxes to free up N2O before downgrading to this plan. Please contact support with any questions'] } }.to_json }
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'DELETE destroy' do
    let!(:billing_profile) { create :billing_profile, user: user }
    let!(:subscription) { create :subscription, state: 'active', billing_profile: billing_profile }

    def do_request(params={})
      delete :destroy, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before do
        sign_in user
      end

      context 'when unsubscription is successful' do
        before do
          user.update_attribute 'max_n2o', 600
          user.update_attribute 'used_n2o', 100
          billing_profile.active_subscription.plan.update_attribute 'n2o_amount', 500

          fake_stripe_customer.stub(:cancel_subscription)
          Stripe::Customer.stub(:retrieve) { fake_stripe_customer }
          do_request
        end

        it { should respond_with :ok }
      end

      context 'when unsubscription fails' do
        before do
          user.update_attribute 'max_n2o', 600
          user.update_attribute 'used_n2o', 600
          billing_profile.active_subscription.plan.update_attribute 'n2o_amount', 500

          do_request
        end

        it { should respond_with :unprocessable_entity }
        its('response.body') { should == { errors: { base: ['You need to terminate boxes to free up N2O before downgrading from current plan. Please contact support with any questions'] } }.to_json }
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
