require 'spec_helper'

describe BoxhostsController do
  let(:user) { create :user }

  describe 'GET index' do
    let!(:boxhost1) { create :dedicated_boxhost, owner: user }
    let!(:boxhost2) { create :dedicated_boxhost, owner: user }
    let!(:boxhost3) { create :dedicated_boxhost, owner: user }
    let!(:another_user) { create :user }
    let!(:boxhost4) { create :dedicated_boxhost, owner: another_user }

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
    let!(:boxhost1) { create :dedicated_boxhost, owner: user }
    let!(:another_user) { create :user }
    let!(:boxhost2) { create :dedicated_boxhost, owner: another_user }

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
    let!(:boxhost1) { create :dedicated_boxhost, owner: user, location: location1 }

    let!(:another_user) { create :user }
    let!(:location2) { create :location }
    let!(:boxhost2) { create :dedicated_boxhost, owner: another_user, location: location2 }

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
    it_behaves_like 'an action that returns 403 when user is not allowed to view dedicated plans'
  end

  describe 'PUT provision' do
    let!(:location1) { create :location }
    let!(:boxhost1) { create :dedicated_boxhost, owner: user, location: location1 }

    let!(:another_user) { create :user }
    let!(:location2) { create :location }
    let!(:boxhost2) { create :dedicated_boxhost, owner: another_user, location: location2 }

    let!(:default_params) { { id: boxhost1.to_param } }

    def do_request(params={ id: boxhost1.to_param })
      put :provision, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when user is allowed to view dedicated plans' do
        before { user.update_attribute(:dedicated_allowed, true) }

        context 'when boxhost belongs to the user' do
          before do
            allow_any_instance_of(DedicatedBoxhost).to receive(:enqueue_provision!)
          end

          it 'sets the provision_webhook of the boxhost to its webhook URL' do
            expect_any_instance_of(DedicatedBoxhost).to receive(:provision_webhook=).with webhook_provisioned_boxhost_url(
              boxhost1,
              user: ENV['BOXHOST_WEBHOOK_USERNAME'],
              password: ENV['BOXHOST_WEBHOOK_PASSWORD'],
            )
            do_request
          end

          it 'provisions the boxhost' do
            expect_any_instance_of(DedicatedBoxhost).to receive(:enqueue_provision!).once
            do_request
          end

          it 'tracks to Mixpanel' do
            expect(TrackMixpanelEventJob).to receive(:submit_job).with(
              'Boxhost provisioned',
              user.id
            )
            do_request
          end

          context do
            before { do_request }
            it { should respond_with :success }
            its('response.body') { should == boxhost1.reload.serialize_as_json }
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
    it_behaves_like 'an action that returns 403 when user is not allowed to view dedicated plans'
  end

  describe '#POST webhook_provisioned' do
    let!(:location) { create :location }
    let!(:boxhost_plan) { create :boxhost_plan }
    let!(:boxhost_provider_template) { create :boxhost_provider_template, location: location, boxhost_plan: boxhost_plan }
    let!(:boxhost) { build :dedicated_boxhost, state: 'provisioning', location: location, boxhost_plan: boxhost_plan, boxhost_provider_template: boxhost_provider_template }

    before do
      allow(boxhost).to receive(:available_templates).and_return([boxhost_provider_template])
      expect(boxhost).to be_valid
      boxhost.save!
    end

    def do_request(payload=nil)
      post :webhook_provisioned, id: boxhost.to_param, payload: JSON.dump(payload)
    end

    context 'when not given HTTP Basic Auth credentials' do
      before { do_request }
      it { should respond_with :unauthorized }
    end

    context 'with the correct HTTP Basic Auth credentials' do
      before do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(ENV['BOXHOST_WEBHOOK_USERNAME'], ENV['BOXHOST_WEBHOOK_PASSWORD'])
      end

      context 'when provisioning is successful' do
        it 'starts the box and saves host ID and IP address' do
          do_request({
            success: true,
            message: JSON.dump(
              id: '123456',
              ip_address: '10.0.0.69',
              provider: 'digitalocean',
            )
          })

          expect(boxhost.reload.state).to eq 'running'
          expect(boxhost.reload.host_identifier).to eq '123456'
          expect(boxhost.reload.ip).to eq '10.0.0.69'

          expect(response.status).to eq 200
          expect(response.body).to eq({ status: 'ok' }.to_json)
        end

        context 'when message does not include host ID' do
          it 'does not start the box' do
            do_request({
              success: true,
              message: JSON.dump(
                ip_address: '10.0.0.69',
                provider: 'digitalocean',
              )
            })

            expect(boxhost.reload.state).to eq 'provisioning'
            expect(boxhost.reload.host_identifier).to eq nil
            expect(boxhost.reload.ip).to eq nil

            expect(response.status).to eq 422
          end
        end

        context 'when message does not include IP address' do
          it 'does not start the box' do
            do_request({
              success: true,
              message: JSON.dump(
                id: '123456',
                provider: 'digitalocean',
              )
            })

            expect(boxhost.reload.state).to eq 'provisioning'
            expect(boxhost.reload.host_identifier).to eq nil
            expect(boxhost.reload.ip).to eq nil

            expect(response.status).to eq 422
          end
        end
      end

      context 'when provisioning is not successful' do
        it 'changes the box to failed state' do
          do_request({
            success: false,
            message: nil
          })

          expect(boxhost.reload.state).to eq 'failed'

          expect(response.status).to eq(200)
          expect(response.body).to eq({ status: 'ok' }.to_json)
        end

        context 'when message includes host ID and IP address' do
          it 'saves them' do
            do_request({
              success: false,
              message: JSON.dump(
              id: '123456',
                ip_address: '10.0.0.69',
                provider: 'digitalocean',
              )
            })

            expect(boxhost.reload.state).to eq 'failed'
            expect(boxhost.reload.host_identifier).to eq '123456'
            expect(boxhost.reload.ip).to eq '10.0.0.69'

            expect(response.status).to eq 200
            expect(response.body).to eq({ status: 'ok' }.to_json)
          end
        end
      end
    end
  end
end
