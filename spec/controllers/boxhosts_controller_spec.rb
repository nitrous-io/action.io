require 'spec_helper'

describe BoxhostsController do
  let(:user) { create :user }

  describe 'GET index' do
    let!(:boxhost1) { create :boxhost, owner: user }
    let!(:boxhost2) { create :boxhost, owner: user }
    let!(:boxhost3) { create :boxhost, owner: user }
    let!(:another_user) { create :user }
    let!(:boxhost4) { create :boxhost, owner: another_user }

    def do_request
      get :index, format: 'json'
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when user is allowed to view dedicated plans' do
        before do
          user.update_attribute(:dedicated_allowed, true)
          Timecop.freeze do
            boxhost3.update_attribute :terminated_at, 1.hour.ago
            do_request
          end
        end

        it 'returns boxhosts visible to the user as json' do
          expect(controller).to respond_with :success
          expect(assigns(:boxhosts)).to match_array [boxhost1, boxhost2]
          expect(response.body).to eq({ boxhosts: assigns(:boxhosts).serialize_as_hash }.to_json)
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
    it_behaves_like 'an action that returns 403 when user is delinquent'
  end
end
