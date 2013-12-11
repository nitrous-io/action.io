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

      it "changes the user's subscription to the given plan" do
        user.should_receive(:change_plan).with(plan)
        do_request(plan_id: plan.id)
      end

      context 'when changing the plan succeeds' do
        before do
          user.stub(:change_plan) { true }
          do_request(plan_id: plan.id)
        end

        it { should respond_with :ok }
      end

      context 'when changing the plan fails' do
        before do
          user.stub(:change_plan) { false }
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

  describe 'PUT change_card' do
    def do_request(params={})
      put :change_card, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before do
        sign_in user
        controller.stub(:current_user) { user }
      end

      it "changes user's card to the given card" do
        user.should_receive(:change_card).with('stripe_token')
        do_request(stripe_token: 'stripe_token')
      end

      context 'when changing the card succeeds' do
        before do
          user.stub(:change_card) { true }
          do_request(stripe_token: 'stripe_token')
        end

        it { should respond_with :ok }
      end

      context 'when changing the card fails' do
        before do
          user.stub(:change_card) { false }
        end

        it 'responds with an unprocessable_entity status' do
          do_request(stripe_token: 'stripe_token')
          expect(controller).to respond_with :unprocessable_entity
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'DELETE destroy' do
    let!(:plan) { create :plan }
    let!(:subscription) { create :subscription, user: user, plan: plan }

    def do_request(params={})
      delete :destroy, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before do
        sign_in user
        controller.stub(:current_user) { user }
      end

      it "cancels the user's existing subscription" do
        user.should_receive(:cancel_subscription)
        do_request
      end

      context 'when the subscription is successfully canceled' do
        before do
          user.stub(:cancel_subscription) { true }
          do_request
        end

        it { should respond_with :ok }
      end

      context 'when we fail to cancel the subscription' do
        before do
          user.stub(:cancel_subscription) { false }
          user.stub(:errors).and_return(base: ['Cannot cancel lah'])

          do_request
        end

        it { should respond_with :unprocessable_entity }
        its('response.body') { should == { errors: { base: ['Cannot cancel lah'] } }.to_json }
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
