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
    end

    it_behaves_like 'an action that returns 403 when user is not allowed to view dedicated plans'
    it_behaves_like 'an action that returns 401 when not signed in'
    it_behaves_like 'an action that returns 403 when user is delinquent'
  end

  describe 'GET show' do
    let!(:boxhost1) { create :boxhost, owner: user }
    let!(:another_user) { create :user }
    let!(:boxhost2) { create :boxhost, owner: another_user }

    def do_request(params={ id: boxhost1.to_param })
      get :show, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when user is allowed to view dedicated plans' do
        before { user.update_attribute(:dedicated_allowed, true) }

        context 'when boxhost belongs to current user' do
          before { do_request id: boxhost1.to_param }

          it { should respond_with :success }
          its('response.body') { should == boxhost1.serialize_as_json }
        end

        context 'when the boxhost belongs to another user' do
          it 'raises record not found' do
            expect {
              do_request id: boxhost2.to_param
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end

        context 'when an invalid id is given' do
          it 'raises record not found' do
            expect {
              do_request id: 'bs id'
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
    it_behaves_like 'an action that returns 403 when user is delinquent'
    it_behaves_like 'an action that returns 403 when user is not allowed to view dedicated plans'
  end

  describe 'PUT update' do
    let!(:location1) { create :location }
    let!(:boxhost1) { create :boxhost, owner: user, location: location1 }

    let!(:another_user) { create :user }
    let!(:location2) { create :location }
    let!(:boxhost2) { create :boxhost, owner: another_user, location: location2 }

    let!(:default_params) { { id: boxhost1.to_param, boxhost: { name: 'my-boxes', location_id: location1.id } } }

    def do_request(params=default_params)
      put :update, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when user is allowed to view dedicated plans' do
        before { user.update_attribute(:dedicated_allowed, true) }

        context 'when boxhost belongs to the user' do
          context 'when boxhost has not been provisioned' do
            before do
              do_request id: boxhost1.to_param, boxhost: { name: 'my-boxes', location_id: location2.id }
            end

            it 'updates the boxhost name and location' do
              expect(boxhost1.reload.name).to eq 'my-boxes'
              expect(boxhost1.reload.location).to eq location2
            end

            it { should respond_with :success }
            its('response.body') { should == boxhost1.reload.serialize_as_json }
          end

          context 'when boxhost has already been provisioned' do
            before do
              boxhost1.update_column(:state, 'running')
            end

            context 'when changing the boxhost name' do
              before do
                do_request id: boxhost1.to_param, boxhost: { name: 'my-boxes' }
              end

              it 'should change the boxhost name' do
                expect(boxhost1.reload.name).to eq 'my-boxes'
              end

              it { should respond_with :success }
              its('response.body') { should == boxhost1.reload.serialize_as_json }
            end

            context 'when trying to change the boxhost location' do
              before do
                do_request id: boxhost1.to_param, boxhost: { name: 'my-boxes', location_id: location2.id }
              end

              it 'should not allow the boxhost location to be changed' do
                expect(boxhost1.reload.location).to eq location1
              end

              it { should respond_with :unprocessable_entity }
              its('response.body') { should == { errors: { location_id: ['Location can no longer be changed.'] } }.to_json }
            end

          end
        end

        context 'when boxhost belongs to another user' do
          it 'raises record not found' do
            expect {
              do_request id: boxhost2.to_param
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end

        context 'when an invalid id is given' do
          it 'raises record not found' do
            expect {
              do_request id: 'bs id'
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
    it_behaves_like 'an action that returns 403 when user is delinquent'
  end
end
