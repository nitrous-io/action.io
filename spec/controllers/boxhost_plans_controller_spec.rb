require 'spec_helper'

describe BoxhostPlansController do
  let(:user) { create :user }

  describe 'GET index' do
    let!(:boxhost_plan1) { create :boxhost_plan }
    let!(:boxhost_plan2) { create :boxhost_plan }

    def do_request
      get :index, format: 'json'
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when user is allowed to view dedicated plans' do
        before { user.update_attribute(:dedicated_allowed, true) }

        it 'returns all boxhost plans as json' do
          do_request
          expect(controller).to respond_with :success
          expect(assigns(:boxhost_plans)).to match_array [boxhost_plan1, boxhost_plan2]
          expect(response.body).to eq({ boxhost_plans: assigns(:boxhost_plans).serialize_as_hash }.to_json)
        end
      end

      context 'when user is not allowed to view dedicated plans' do
        it 'responds with forbidden' do
          do_request
          expect(controller).to respond_with :forbidden
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'GET show' do
    let!(:boxhost_plan) { create :boxhost_plan }

    def do_request(params={ id: boxhost_plan.to_param })
      get :show, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when user is allowed to view dedicated plans' do
        before { user.update_attribute(:dedicated_allowed, true) }

        it 'returns the requested boxhost plan as json' do
          do_request id: boxhost_plan.to_param

          expect(controller).to respond_with :success
          expect(assigns(:boxhost_plan)).to eq boxhost_plan
          expect(response.body).to eq boxhost_plan.serialize_as_json
        end
      end

      context 'when user is not allowed to view dedicated plans' do
        it 'responds with forbidden' do
          do_request
          expect(controller).to respond_with :forbidden
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
