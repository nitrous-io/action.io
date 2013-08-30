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
      let!(:stripe_customer) { OpenStruct.new(id: 'id_01',
                                            cards: OpenStruct.new(
                                              data: [ OpenStruct.new(last4: '1234', type: 'Visa', exp_month: 10, exp_year: 2014 ) ]
                                            ))
                           }
      before do
        sign_in user
        Stripe::Customer.stub(:create) { stripe_customer }
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
          expect(response.body).to eq({ base: ['invalid request'] }.to_json)
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
    let!(:billing_profile) { create :billing_profile, user: user, plan: subscription_plan }


    def do_request(params={})
      put :update, { format: 'json'}.merge(params)
    end

    context 'when signed in' do
      let!(:stripe_token) { 'abcdefghighkl' }
      let!(:stripe_customer) { OpenStruct.new(id: 'id_01',
                                            cards: OpenStruct.new(
                                              data: [ OpenStruct.new(last4: '1234', type: 'Visa', exp_month: 10, exp_year: 2014 ) ]
                                            ))
                             }
      before do
        sign_in user

        Stripe::Customer.stub(:retrieve) { stripe_customer }
      end

      context 'when stripe token is provided' do
        context 'when the billing profile is updated without any errors' do
          before do
            stripe_customer.stub(:save) { null }
          end

          it 'responds with a success status' do
            do_request({ stripe_token: stripe_token })
            expect(controller).to respond_with :ok
          end
        end

        context 'when the billing profile is not updated due to errors' do
          it 'responds with an unprocessable_entity status' do
            do_request({ stripe_token: stripe_token })
            expect(controller).to respond_with :unprocessable_entity
          end

          it 'response body contains an error message' do
            do_request({ stripe_token: stripe_token })
            expect(response.body).to eq({ base: ['invalid request'] }.to_json)
          end
        end
      end

      context 'when a subscription plan id is provided' do
        it 'calls change plan with given plan id' do
          billing_profile.should_receive(:change_plan).with(subscription_plan.id)
          do_request({ plan_id: subscription_plan.id })
        end

        it 'responds with a success status' do
          do_request({ plan_id: subscription_plan.id })
          expect(controller).to respond_with :ok
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
