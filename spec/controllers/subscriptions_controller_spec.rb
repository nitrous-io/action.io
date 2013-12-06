require 'spec_helper'

describe SubscriptionsController do
  let!(:user) { create :user }

  describe 'POST create' do
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
        it 'responds with an unprocessable_entity status' do
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
    let!(:plan) { create :plan }

    def do_request(params={})
      put :update, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before do
        sign_in user
        controller.stub(:current_user) { user }
      end

      it "updates the user's subscription to the given plan" do
        user.should_receive(:update_subscription).with(plan)
        do_request(plan_id: plan.id)
      end

      context 'when updating the subscription succeeds' do
        before do
          user.stub(:update_subscription) { true }
          do_request(plan_id: plan.id)
        end

        it { should respond_with :ok }
      end

      context 'when updating the subscription fails' do
        before do
          user.stub(:update_subscription) { false }
        end

        it 'responds with an unprocessable_entity status' do
          do_request(plan_id: plan.id)
          expect(controller).to respond_with :unprocessable_entity
        end
      end

      context 'when the plan does not exist' do
        it 'raises a record not found error' do
          expect {
            do_request(plan_id: 'bullshit id')
          }.to raise_error ActiveRecord::RecordNotFound
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
