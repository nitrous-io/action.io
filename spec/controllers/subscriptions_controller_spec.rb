require 'spec_helper'

describe SubscriptionsController do
  let(:user) { create :user }

  describe 'POST create' do
    def do_request(params={})
      post :create, { format: 'json'}.merge(params)
    end

    context 'when signed in' do
      let!(:plan) { create :subscription_plan }
      let!(:stripe_token) { 'abcdefghighkl' }
      let!(:stripe_customer) do
        OpenStruct.new(id: 'id_01',
                       cards: OpenStruct.new(
                         data: [ OpenStruct.new(last4: '1234', type: 'Visa', exp_month: 10, exp_year: 2014 ) ]
                       ))
      end
      let(:channel) { double.as_null_object }

      before do
        sign_in user
        Stripe::Customer.stub(:create) { stripe_customer }

        Pusher.stub(:[]).with("private-user-#{user.id}") { channel }
        channel.stub(:trigger)
      end

      context 'when both stripe_token and plan are provided' do
        it 'creates a new billing profile for the user' do
          expect {
            do_request({ plan_id: plan.id, stripe_token: stripe_token })
          }.to change { BillingProfile.count }.by 1

          billing_profile = BillingProfile.last
          expect(billing_profile.user).to eq(user)
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
    let!(:subscription_plan) { create :subscription_plan }
    let!(:billing_profile) { create :billing_profile, user: user }

    def do_request(params={})
      put :update, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      let!(:stripe_token) { 'abcdefghighkl' }

      before do
        sign_in user
      end

      context 'billing profile is updated' do
        before do
          expect_any_instance_of(BillingProfile).to receive(:update_subscription).and_return true
          do_request({ stripe_token: stripe_token, plan_id: subscription_plan.id  })
        end

        it { should respond_with :ok }
      end

      context 'profile is not saved and returns errors' do
        before do
          expect_any_instance_of(BillingProfile).to receive(:update_subscription).and_return false
          do_request({stripe_token: stripe_token, plan_id: subscription_plan.id  })
        end

        it { should respond_with :unprocessable_entity }
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
          user.update_attribute 'max_n2o', 1000
          user.update_attribute 'used_n2o', 100
          billing_profile.active_subscription.plan.update_attribute 'n2o_amount', 500

          fake_stripe_customer = double()
          fake_stripe_customer.stub(:cancel_subscription)
          Stripe::Customer.stub(:retrieve) { fake_stripe_customer }
          do_request
        end

        it { should respond_with :ok }
      end

      context 'when unsubscription fails' do
        before do
          user.update_attribute 'max_n2o', 1000
          user.update_attribute 'used_n2o', 600
          billing_profile.active_subscription.plan.update_attribute 'n2o_amount', 500

          do_request
        end

        it { should respond_with :unprocessable_entity }
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
