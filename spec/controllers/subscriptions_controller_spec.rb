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
      before do
        sign_in user
      end

      it 'creates a new billing profile for the user' do
        expect {
          do_request({ plan_id: plan.id, stripe_token: stripe_token })
        }.to change { BillingProfile.count }.by 1

        billing_profile = BillingProfile.last
        expect(billing_profile.user).to eq(user)
      end

      it 'a new Stripe job should be queued with supplied plan and stripe token' do
        expect {
          do_request({ plan_id: plan.id, stripe_token: stripe_token })
        }.to change { Delayed::Job.count }.by 1

        job_payload = Delayed::Job.last.payload_object
        expect(job_payload.plan_id).to eq(plan.id)
        expect(job_payload.stripe_token).to eq(stripe_token)
      end

      it 'responds with an accepted status' do
        do_request({ plan_id: plan.id, stripe_token: stripe_token })
        expect(controller).to respond_with :accepted
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'PUT update' do
    let!(:billing_profile) { create :billing_profile, user: user }
    def do_request(params={})
      put :update, { format: 'json'}.merge(params)
    end

    context 'when signed in' do
      let!(:stripe_token) { 'abcdefghighkl' }
      before do
        sign_in user
      end

      it 'queues a job to update on Stripe end' do
        expect {
          do_request({ stripe_token: stripe_token })
        }.to change { Delayed::Job.count }.by 1

        job_payload = Delayed::Job.last.payload_object
        expect(job_payload.plan_id).to eq(nil)
        expect(job_payload.stripe_token).to eq(stripe_token)
      end

      it 'responds with an accepted status' do
        do_request({ stripe_token: stripe_token })
        expect(controller).to respond_with :accepted
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
