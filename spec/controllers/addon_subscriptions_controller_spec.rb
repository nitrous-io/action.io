require 'spec_helper'

describe AddonSubscriptionsController do
  let!(:user) { create :user }
  let!(:box) { create :box, owner: user }

  describe 'GET index' do
    let!(:subscription1) { create :addon_subscription, box: box, state: "deprovisioned" }
    let!(:subscription2) { create :addon_subscription, box: box }
    let!(:other_subscription) { create :addon_subscription }

    def do_request(id=box.id)
      get :index, box_id: id, format: 'json'
    end

    context 'when signed in' do
      before { sign_in user }

      it 'returns a list of current user subscriptions for the box' do
        do_request
        response.should be_success
        assigns(:addon_subscriptions).should =~ [subscription2]
      end

      it 'doesnt returns the subscritions list for non-owned boxes' do
        another_user = create :user
        hackintosh = create :box, owner: another_user, users: [another_user, user]
        expect {
          do_request hackintosh.id
        }.to raise_error
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'POST create' do
    let(:addon_plan) { create :addon_plan }
    let(:box_id) { box.id }

    def do_request(options={})
      post :create, format: 'json', addon_subscription: {
        box_id: box_id,
        addon_plan_id: addon_plan.id
      }.merge(options)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when the request is valid' do
        before do
          AddonSubscription.any_instance.stub :push_addon_updated_message
        end

        it 'creates a new addon subscription' do
          do_request
          subscription = assigns(:subscription)
          subscription.should be_persisted
          subscription.addon_plan.should eq(addon_plan)
          subscription.box.should eq(box)
        end

        it 'schedules the subscription to be provisioned' do
          do_request
          job = Delayed::Job.last
          subscription = assigns(:subscription)
          job.payload_object.addon_subscription_id.should eq(subscription.id)
        end
      end

      it 'fails when receives invalid addon' do
        expect { do_request addon_plan_id: "ballmer" }.to raise_error
      end

      it 'fails when receives invalid box' do
        expect { do_request box_id: "ballmer" }.to raise_error
      end

      it 'fails when receives box of another user' do
        another_user = create :user
        hackintosh = create :box, owner: another_user, users: [another_user, user]
        expect { do_request box_id: hackintosh.id }.to raise_error
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'GET show' do
    let(:subscription) { create :addon_subscription, box: box }

    def do_request(id=subscription.id)
      get :show, format: 'json', id: id
    end

    context 'when signed in' do
      before { sign_in user }

      it 'returns the subscription' do
        do_request
        assigns(:subscription).should eq(subscription)
      end

      it 'fails when receives subscription of another user' do
        another_user = create :user
        hackintosh = create :box, owner: another_user, users: [another_user, user]
        subscription = create :addon_subscription, box: hackintosh
        expect { do_request subscription.id }.to raise_error
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'DELETE destroy' do
    let(:subscription) { create :addon_subscription, box: box, state: "provisioned" }

    def do_request(id=subscription.id)
      delete :destroy, format: 'json', id: id
    end

    before do
      AddonSubscription.any_instance.stub :push_addon_updated_message
    end

    context 'when signed in' do
      before { sign_in user }

      it 'deprovision the subscription' do
        do_request
        payload = Delayed::Job.last.payload_object
        payload.addon_subscription_id.should eq(subscription.id)
        payload.object.should be_kind_of(DeprovisionAddonJob)
      end

      it 'fails when the subscrition is not in subscribed state' do
        subscription.update_attribute :state, :provisioning
        do_request
        response.code.should eq("422")
      end

      it 'fails when receives subscription of another user' do
        another_user = create :user
        hackintosh = create :box, owner: another_user, users: [another_user, user]
        subscription = create :addon_subscription, box: hackintosh
        expect { do_request subscription.id }.to raise_error
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
