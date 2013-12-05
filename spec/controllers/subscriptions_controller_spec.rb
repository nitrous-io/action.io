require 'spec_helper'

describe SubscriptionsController do
  let!(:user) { create :user }

  describe 'POST create', focus: true do
    def do_request(params={})
      post :create, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      let!(:plan) { create :plan }
      before do
        sign_in user
        controller.stub(:current_user) { user }
      end

      context 'when both stripe_token and plan are provided' do
        it 'should subscribe the user to the given plan' do
          user.should_receive(:subscribe).with(plan, 'abcdef')
          do_request(plan_id: plan.id, stripe_token: 'abcdef')
        end

        it 'responds with a created status' do
          user.stub(:subscribe) { true }
          do_request(plan_id: plan.id, stripe_token: 'abc')
          expect(controller).to respond_with :created
        end
      end

      context 'when stripe token is not provided' do
        it 'responds with a unprocessable_entity status' do
          do_request(plan_id: plan.id, stripe_token: nil)
          expect(controller).to respond_with :unprocessable_entity
        end
      end

      context 'when subscription plan is not provided' do
        it 'raises record not found' do
          expect {
            do_request(plan_id: nil, stripe_token: 'abc')
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
