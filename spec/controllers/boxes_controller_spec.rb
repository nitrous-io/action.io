require 'spec_helper'

describe BoxesController do
  let(:user) { create :user }

  before do
    Box.any_instance.stub(:coach) { NullCoach.new(mock_model(Box).as_null_object) }
  end

  describe 'GET index' do
    let!(:another_user) { create :user }
    let!(:box) { create :box, owner: user, users: [user] }
    let!(:box2) { create :box, owner: user, users: [user] }
    let!(:box3) { create :box, owner: user, users: [user] }
    let!(:box4) { create :box, owner: another_user, users: [another_user, user] }

    def do_request
      get :index, format: 'json'
    end

    context 'when signed in' do
      before do
        sign_in user
        Timecop.freeze do
          box2.update_attribute :terminated_at, 1.day.ago + 1.second
          box3.update_attribute :terminated_at, 1.day.ago
          do_request
        end
      end

      it { should respond_with :success }

      it "returns the current user's boxes as json" do
        response.body.should eq({ boxes: [box, box2, box4].serialize_as_hash }.to_json)
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'POST create' do
    def do_request(params={ box: {} })
      post :create, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before do
        sign_in user
      end

      context 'with valid params' do
        let!(:rails_box_template) { create :box_template, runtime: 'rails', enabled: true }
        let(:region) { create :region, enabled: true }
        let(:params) { { box: { name: 'fragrant-wind-69', region_id: region.to_param, box_template_id: rails_box_template.to_param } } }
        let!(:coach) { double :coach }

        before do
          Box.any_instance.stub(:push_box_updated_message)
          Box.any_instance.stub(:coach).and_return(coach)
          coach.stub!(:provision_box).and_return(true)
        end

        context "when user hasn't created any boxes yet" do
          it 'creates and persists a box object for the current user with rails box template' do
            IncrementMixpanelPropertyJob.should_receive(:submit_job).with(user.id, :boxes_created, 1)
            TrackMixpanelEventJob.should_receive(:submit_job).with('Box Created', user.id)

            expect {
              do_request(params)
            }.to change { Box.count }.by 1

            box = Box.last
            box.name.should == params[:box][:name]
            box.region.should == region
            box.box_template.should == rails_box_template
            box.users.should == [user]
            box.owner.should == user
          end

          context do
            before { do_request(params) }

            it { should respond_with :created }
            its('response.body') { should == Box.last.serialize_as_json }
          end

          context "call to coach" do
            it 'should make a call to provision_box on coach' do
              coach.should_receive(:provision_box).and_return(true)
              do_request(params)
            end
          end
        end

        context 'when "region" parameter is given instead of "region_id"' do
          let!(:africa_region) { create :region, name: 'africa', enabled: true }
          let!(:antartica_region) { create :region, name: 'antartica', enabled: true }

          before do
            params[:box].delete(:region_id)
            params[:box][:region] = 'africa'
          end

          it 'looks for region by name and uses that instead' do
            expect {
              do_request(params)
            }.to change { Box.count }.by 1

            box = Box.last
            box.region.should == africa_region
          end
        end

        context 'when "box_template" paramter is given instead of "box_template_id"' do
          let!(:scala_box_template)  { create :box_template, runtime: 'scala', enabled: true }
          let!(:erlang_box_template) { create :box_template, runtime: 'erlang', enabled: true }

          before do
            params[:box].delete(:box_template_id)
            params[:box][:box_template] = 'scala'
          end

          it 'looks for box_template by name and uses that instead' do
            expect {
              do_request(params)
            }.to change { Box.count }.by 1

            box = Box.last
            box.box_template.should == scala_box_template
          end
        end

        context 'with a region where box creation is disabled' do
          before { region.update_attribute :state, 'box_creation_disabled' }

          it 'does not create a box object' do
            expect {
              do_request(params)
            }.not_to change { Box.count }.by 1
          end

          context do
            before { do_request }

            it { should respond_with :unprocessable_entity }
            it { assigns(:box).should_not be_persisted }
          end
        end

        context 'with a disabled region' do
          before { region.update_attribute :enabled, false }

          it 'does not create a box object' do
            expect {
              do_request(params)
            }.not_to change { Box.count }.by 1
          end

          context do
            before { do_request }

            it { should respond_with :unprocessable_entity }
            it { assigns(:box).should_not be_persisted }
          end
        end

        context 'with a disabled box template' do
          before { rails_box_template.update_attribute :enabled, false }

          it 'does not create a box object' do
            expect {
              do_request(params)
            }.not_to change { Box.count }.by 1
          end

          context do
            before { do_request }

            it { should respond_with :unprocessable_entity }
            it { assigns(:box).should_not be_persisted }
          end
        end

        context 'with an admin box template' do
          before { rails_box_template.update_attribute :admin, true }

          it 'does not create a box object' do
            expect {
              do_request(params)
            }.not_to change { Box.count }.by 1
          end

          context do
            before { do_request }

            it { should respond_with :unprocessable_entity }
            it { assigns(:box).should_not be_persisted }
          end
        end

        context 'when user has shared boxes' do
          let(:another_user) { create :user }
          let!(:box_1) { create :box, owner: another_user, users: [ another_user, user ] }
          let!(:box_2) { create :box, owner: another_user, users: [ another_user, user ] }
          let!(:box_3) { create :box, owner: user }

          it 'creates a new box' do
            expect {
              do_request(params)
            }.to change { Box.count }.by(1)
          end

          context do
            before { do_request(params) }

            it { should respond_with :created }
            its('response.body') { should == Box.last.serialize_as_json }
          end
        end
      end

      context 'with invalid params' do
        context 'with no params' do
          it 'does not create a box object' do
            expect {
              do_request
            }.not_to change { Box.count }.by 1
          end

          context do
            before { do_request }

            it { should respond_with :unprocessable_entity }
            it { assigns(:box).should_not be_persisted }
          end
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'GET show' do
    let(:another_user) { create :user }
    let!(:box1) { create :box, users: [user] }
    let!(:box2) { create :box, users: [another_user] }

    def do_request(params={ id: '1' })
      get :show, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when a valid id is given' do
        context 'when the box belongs to the current user' do
          before { do_request id: box1.to_param }

          it { should respond_with :success }
          its('response.body') { should == box1.serialize_as_json }
        end

        context 'when the box belongs to another user' do
          it 'raises record not found' do
            expect {
              do_request id: box2.to_param
            }.to raise_error ActiveRecord::RecordNotFound
          end
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

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'PUT update' do
    let(:another_user) { create :user }
    let!(:box1) { create :box, owner: user, memory: 384, storage: 750 }
    let!(:box2) { create :box, owner: another_user }

    before do
      create 'key_value', key: N2oAllocation::N2O_128MB_MEMORY,  value: 40
      create 'key_value', key: N2oAllocation::N2O_250MB_STORAGE, value: 10

      n2o_alloc = box1.n2o_allocations.build
      n2o_alloc.user = user
      n2o_alloc.kind = N2oAllocation::Kind::BOX_CREATION
      n2o_alloc.amount = box1.n2o_cost
      n2o_alloc.save!
    end

    def do_request(params={ id: box1.to_param, box: { memory: '512', storage: '1250' } })
      put :update, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when a valid id is given' do
        context 'when the box belongs to the current user' do

          before do
            box1.update_attributes({ memory: 384, storage: 750 })
          end

          context 'when user has enough n2o to upgrade the box' do
            before do
              user.fill_n2o! 250, 0
              TrackMixpanelEventJob.should_receive(:submit_job).with('Box Specs Changed', user.id)
              do_request
            end

            it { should respond_with :success }
            its('response.body') { should == box1.reload.serialize_as_json }
          end

          context 'when user dont have enough n2o to upgrade the box' do
            before do
              user.n2o_fills.delete_all
              TrackMixpanelEventJob.should_not_receive(:submit_job).with('Box Specs Changed', user.id)
              do_request
            end

            it { should respond_with :unprocessable_entity }
            its('response.body') { should == {errors: {base: ["Not enough N2O"]}}.to_json }
          end

          # FIXME: couldn't get this spec to pass
          # but feature works in the app
          context 'when user dont have n2o but downgrade the box' do
            before do
              user.n2o_fills.delete_all
              TrackMixpanelEventJob.should_receive(:submit_job).with('Box Specs Changed', user.id)
              do_request({ id: box1.to_param, box: { memory: '256', storage: '250' } })
            end

            it { should respond_with :success }
            its('response.body') { should == box1.reload.serialize_as_json }
          end
        end

        context 'when the box belongs to another user' do
          it 'raises record not found' do
            expect {
              do_request id: box2.to_param
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end
      end

      context 'when an invalid id is given' do
        it 'raises record not found' do
          expect {
            do_request id: 'bs id'
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      it_behaves_like 'an action that returns 422 when the backend is not available', action: :change_specs!
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'DELETE destroy' do
    let(:another_user) { create :user }
    let!(:box1) { create :box, owner: user, state: 'stopped' }
    let!(:box2) { create :box, owner: another_user, state: 'stopped' }

    def do_request(params={ id: '1' })
      delete :destroy, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when a valid id is given' do
        context 'when the box belongs to the current user' do
          let(:params) { { id: box1.to_param } }

          before do
            IncrementMixpanelPropertyJob.should_receive(:submit_job).with(user.id, :boxes_created, -1)
            TrackMixpanelEventJob.should_receive(:submit_job).with('Box Terminated', user.id)

            Box.any_instance.should_receive(:enqueue_terminate!).once
            do_request params
          end

          it { should respond_with :no_content }
        end

        context 'when the box belongs to another user' do
          it 'raises record not found' do
            expect {
              do_request id: box2.to_param
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end
      end

      context 'when an invalid id is given' do
        it 'raises record not found' do
          expect {
            do_request id: 'bs id'
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      it_behaves_like 'an action that returns 422 when the backend is not available', action: :enqueue_terminate!
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'GET terminal' do
    let!(:another_user) { create :user }
    let!(:box1) { create :box, owner: user,         users: [user] }
    let!(:box2) { create :box, owner: another_user, users: [another_user] }
    let!(:box3) { create :box, owner: user,         users: [user] }

    def do_request(params={ id: '1' })
      get :terminal, params
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when a valid id is given' do
        context 'when the box belongs to the current user' do
          before { do_request id: box1.to_param }

          it { should respond_with :success }
          it { assigns(:box).should == box1 }
          it { should render_template 'terminal' }
        end

        context 'when the box belongs to another user' do
          it 'raises record not found' do
            expect {
              do_request id: box2.to_param
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end
      end

      context 'when an invalid id is given' do
        it 'raises record not found' do
          expect {
            do_request id: 'bs id'
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      it_behaves_like 'an action that returns 422 when the backend is not available'
    end

    it_behaves_like 'an action that requires sign in'
  end

  shared_examples 'a box control action that tracks mixpanel properties and events' do |options|
    action = options[:action]
    previous_state = options[:previous_state]
    mixpanel_event = options[:mixpanel_event]
    mixpanel_property = options[:mixpanel_property]
    mixpanel_value = options[:mixpanel_value]

    let!(:box1) { create :box, users: [user], state: previous_state }

    define_method :do_request do |params={ id: '1' }|
      put action, { format: 'json' }.merge(params)
    end

    let(:params) { { id: box1.to_param } }

    before do
      sign_in user
      Box.any_instance.should_receive(:"enqueue_#{action}!")
      IncrementMixpanelPropertyJob.should_receive(:submit_job).with(user.id, mixpanel_property, mixpanel_value)
      TrackMixpanelEventJob.should_receive(:submit_job).with(mixpanel_event, user.id)
      do_request params
    end
  end

  shared_examples 'a box control action' do |options|
    action = options[:action]
    previous_state = options[:previous_state]

    let(:another_user) { create :user }
    let!(:box1) { create :box, owner: user, state: previous_state }
    let!(:box2) { create :box, owner: another_user, state: previous_state }

    define_method :do_request do |params={ id: '1' }|
      put action, { format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when a valid id is given' do
        context 'when the box belongs to the current user' do
          let(:params) { { id: box1.to_param } }

          before do
            Box.any_instance.should_receive(:"enqueue_#{action}!")
            do_request params
          end

          it { should respond_with :success }
          its('response.body') { should == box1.reload.serialize_as_json }
        end

        context 'when the box belongs to another user' do
          it 'raises record not found' do
            expect {
              do_request id: box2.to_param
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end

        context 'when the box belongs to a collabarator' do
          before do
            box2.users << user
          end

          it 'raises record not found' do
            expect {
              do_request id: box2.to_param
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end
      end

      context 'when an invalid id is given' do
        it 'raises record not found' do
          expect {
            do_request id: 'bs id'
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      it_behaves_like 'an action that returns 422 when the backend is not available', action: :"enqueue_#{action}!"
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'PUT start' do
    it_behaves_like 'a box control action', action: :start,   previous_state: :stopped
    it_behaves_like 'a box control action that tracks mixpanel properties and events', action: :start, previous_state: :stopped, mixpanel_event: 'Box Started', mixpanel_property: :boxes_running, mixpanel_value: 1
  end

  describe 'PUT stop' do
    it_behaves_like 'a box control action', action: :stop,    previous_state: :running
    it_behaves_like 'a box control action that tracks mixpanel properties and events', action: :stop, previous_state: :running, mixpanel_event: 'Box Stopped', mixpanel_property: :boxes_running, mixpanel_value: -1
  end

  describe 'PUT restart' do
    it_behaves_like 'a box control action', action: :restart, previous_state: :running
    it_behaves_like 'a box control action that tracks mixpanel properties and events', action: :restart, previous_state: :running, mixpanel_event: 'Box Restarted'
  end

  describe 'PUT provision' do
    it_behaves_like 'a box control action', action: :provision, previous_state: :failed
    it_behaves_like 'a box control action that tracks mixpanel properties and events', action: :provision, previous_state: :failed, mixpanel_event: 'Box Provisioning Retried'
  end

  describe 'PUT webhook' do
    let!(:box) { create :box }

    before :each do
      Box.any_instance.stub(:push_box_updated_message) { nil }

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(ENV['WEBHOOK_USERNAME'], ENV['WEBHOOK_PASSWORD'])
    end

    def do_request(payload)
      put :webhook, id: box.id, payload: payload
    end

    context 'Received aio:created message from the Coach' do
      let!(:coach) { double :coach }

      before do
        Box.any_instance.stub(:coach).and_return(coach)
        coach.stub!(:start_box).and_return(true)
        box.update_attribute(:state, 'provisioning')
      end

      context 'successful creation' do
        it 'should start the box' do
          coach.should_receive(:start_box).and_return(true)

          do_request('{"type":"aio:created","success":true,"port":10000,"id":"apse1-1.actionbox.io"}')

          box.reload.host.should == 'apse1-1.actionbox.io'
          box.port.should == 10000
          box.state.should == 'starting'

          response.status.should == 200
          expect(response.body).to eq({status: 'ok'}.to_json)
        end
      end

      context 'unsuccessful creation' do
        it 'should NOT make a call to the coach to start the box, but transition from provisioning to born' do
          coach.should_not_receive(:start_box)

          do_request('{"type":"aio:created","success":false}')

          box.reload.state.should == 'failed'
          response.status.should == 200
          expect(response.body).to eq({status: 'ok'}.to_json)
        end
      end
    end

    context 'Received aio:started message from the Coach' do
      before { box.update_attribute(:state, 'starting') }

      it 'should change the state of the box from starting to running' do
        do_request('{"type":"aio:started","boxId":1,"name":"rails-box"}')

        box.reload.state.should == 'running'
        response.status.should == 200
        expect(response.body).to eq({status: 'ok'}.to_json)
      end
    end

    context 'Received aio:stopped message from the Coach' do
      before { box.update_attribute(:state, 'stopping') }

      it 'should change the state of the box from stopping to stopped' do
        do_request('{"type":"aio:stopped","boxId":1,"name":"rails-box"}')

        box.reload.state.should == 'stopped'
        response.status.should == 200
        expect(response.body).to eq({status: 'ok'}.to_json)
      end
    end

    context 'Received aio:restarted message from the Coach' do
      before { box.update_attribute(:state, 'restarting') }

      it 'should change the state of the box from restarting to running' do
        do_request('{"type":"aio:restarted","boxId":1,"name":"rails-box"}')

        box.reload.state.should == 'running'
        response.status.should == 200
        expect(response.body).to eq({status: 'ok'}.to_json)
      end
    end

    context 'Received aio:destroyed message from the Coach' do
      before { box.update_attribute(:state, 'terminating') }

      it 'should change the state of the box from terminating to terminated' do
        do_request('{"type":"aio:destroyed","boxId":1,"name":"rails-box"}')

        box.reload.state.should == 'terminated'
        response.status.should == 200
        expect(response.body).to eq({status: 'ok'}.to_json)
      end
    end

    context 'Received aio:info_response message from the Coach' do
      let(:channel) { stub.as_null_object }

      it 'should send a message via websockets with the box info' do
        Pusher.should_receive(:[]).with("private-user-#{box.owner.id}") { channel }
        channel.should_receive(:trigger) do |message, data|
          message.should eq 'aio:box_info_response'
          data.should eq({box: { id: box.id, memory_usage: 256, storage_usage: 1000, lxc_status: 'RUNNING' }}.to_json)
        end

        do_request('{"type":"aio:info_response","boxId":1,"name":"rails-box","info":{"memoryUsage":256,"storageUsage":1000,"lxcStatus":"RUNNING"}}')

        response.status.should == 200
        expect(response.body).to eq({status: 'ok'}.to_json)
      end
    end
  end

  describe 'POST add_public_key_to_github' do
    def do_request(params={ id: '1' })
      post :add_public_key_to_github, params
    end

    let!(:box1) { create :box, owner: user, users: [user] }
    let(:another_user) { create :user }
    let(:box2) { create :box, owner: another_user, users: [another_user] }

    context 'when signed in' do
      before { sign_in user }

      it 'fires up a delayed job to setups the github key for the selected box' do
        IncrementMixpanelPropertyJob.should_receive(:submit_job).with(user.id, :public_keys_added_to_github, 1)
        TrackMixpanelEventJob.should_receive(:submit_job).with('Github Added Key', user.id)

        expect {
          do_request id: box1.to_param
        }.to change { Delayed::Job.count }.by(1)
        response.should be_success
        expect(response.body).to eq({status: 'ok'}.to_json)
      end

      it 'raises record not found when the box belongs to another user' do
        expect {
          do_request id: box2.to_param
        }.to raise_error ActiveRecord::RecordNotFound
      end

      it_behaves_like 'an action that returns 422 when the backend is not available'
    end

    it_behaves_like 'an action that requires sign in'
  end

  describe 'GET info' do
    def do_request(params={ id: '1' })
      get :info, params
    end

    let!(:box1)         { create :box, owner: user, users: [user] }
    let(:another_user)  { create :user }
    let(:box2)          { create :box, owner: another_user, users: [another_user] }

    context 'when signed in' do
      before { sign_in user }

      it 'fires up a delayed job to get info from Coach for the box' do
        expect {
          do_request id: box1.to_param
        }.to change { Delayed::Job.count }.by(1)

        expect(Delayed::Job.first.handler).to match(/FetchBoxInfoJob.*?box_id: #{box1.id}/m)
        expect(Delayed::Job.first.handler).to match(/FetchBoxInfoJob.*?user_id: #{user.id}/m)

        response.should be_success
        expect(response.body).to eq({status: 'ok'}.to_json)
      end

      it 'raises record not found when the box belongs to another user' do
        expect {
          do_request id: box2.to_param
        }.to raise_error ActiveRecord::RecordNotFound
      end

      it_behaves_like 'an action that returns 422 when the backend is not available'
    end

    it_behaves_like 'an action that requires sign in'
  end

  describe 'GET default_public_key' do
    def do_request(params={ id: '1' })
      get :default_public_key, params
    end

    let!(:box1) { create :box, owner: user, users: [user] }
    let(:another_user) { create :user }
    let(:box2) { create :box, owner: another_user, users: [another_user] }

    context 'when signed in' do
      before { sign_in user }

      it 'fires up a delayed job to setups the github key for the selected box' do
        expect {
          do_request id: box1.to_param
        }.to change { Delayed::Job.count }.by(1)

        response.should be_success
        expect(response.body).to eq({status: 'ok'}.to_json)
      end

      it 'raises record not found when the box belongs to another user' do
        expect {
          do_request id: box2.to_param
        }.to raise_error ActiveRecord::RecordNotFound
      end

      it_behaves_like 'an action that returns 422 when the backend is not available'
    end

    it_behaves_like 'an action that requires sign in'
  end

  describe 'POST touch' do
    let!(:box) { create :box, touched_at: 1.day.ago }

    def do_request(params={ id: box.to_param })
      post :touch, params
    end

    context 'when box exists' do
      it 'enqueues a delayed job to post a mixpanel event for each of the box user and updates touched_at' do
        TrackMixpanelEventJob.should_receive(:submit_job).with 'SSH Session Started', box.owner.id
        Timecop.freeze do
          do_request
          controller.should respond_with :success
          expect(response.body).to eq({status: 'ok'}.to_json)
          expect(box.reload.touched_at.to_i).to eq(Time.zone.now.to_i)
        end
      end
    end

    context 'when box does not exist' do
      it 'raises record not found exception' do
        expect {
          do_request id: '9001'
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end
