require 'spec_helper'

describe BoxesController do
  let(:user) { create :user }

  before do
    allow_any_instance_of(Box).to receive(:coach) { NullCoach.new(mock_model(Box).as_null_object) }
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
        expect(response.body).to eq({ boxes: [box, box4].serialize_as_hash }.to_json)
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'POST create' do
    def do_request(params={ box: {} })
      post :create, { format: 'json' }.merge(params)
    end

    before do
      KeyValue.create key: Box::N2O_MIN_MEMORY_MB,  value: 384
      KeyValue.create key: Box::N2O_MIN_STORAGE_MB, value: 1000
    end

    context 'when signed in' do
      before do
        sign_in user
      end

      context 'with valid params' do
        let!(:region) { create :region, enabled: true }
        let!(:coach) { instance_double('Coach') }

        before do
          allow(IncrementMixpanelPropertyJob).to receive(:submit_job).with(user.id, :boxes_created, 1)
        end

        context 'when creating box from a box template' do
          let!(:rails_box_template) { create :box_template, runtime: 'rails', enabled: true }
          let(:params) { { box: { name: 'fragrant-wind-69', region_id: region.to_param, box_template_id: rails_box_template.to_param, memory: 1024, storage: 750 } } }

          before do
            allow_any_instance_of(Box).to receive(:push_box_updated_message)
            allow_any_instance_of(Box).to receive(:coach).and_return(coach)
            coach.stub(:provision_box).and_return(true)
          end

          context do
            before { do_request(params) }

            it { should respond_with :created }
            its('response.body') { should == Box.last.serialize_as_json }
          end

          it 'creates and persists a box object for the current user with rails box template' do
            expect(IncrementMixpanelPropertyJob).to receive(:submit_job).with(user.id, :boxes_created, 1)
            expect(TrackMixpanelEventJob).to receive(:submit_job).with('Box Created', user.id, hash_including(memory: an_instance_of(Fixnum), storage: an_instance_of(Fixnum), template: rails_box_template.name, region: region.name))

            expect {
              do_request(params)
            }.to change { Box.count }.by 1

            box = Box.last
            expect(box.name).to eq(params[:box][:name])
            expect(box.region).to eq(region)
            expect(box.box_template).to eq(rails_box_template)
            expect(box.users).to eq([user])
            expect(box.owner).to eq(user)
          end

          it 'should make a call to provision_box on coach' do
            expect(coach).to receive(:provision_box).and_return(true)
            do_request(params)
          end

          context 'when two concurrent box creation requests happen' do
            let!(:kv1)  { create :key_value, key: N2oAllocation::N2O_128MB_MEMORY,  value: 40 }
            let!(:kv2)  { create :key_value, key: N2oAllocation::N2O_250MB_STORAGE, value: 10 }
            # The cost of creating the one box in this spec is 350 (according to the values specified in kv1 and kv2)
            # so fill the user with 350 n2o
            let!(:fill) { create :n2o_fill, user: user, amount: 360 }

            it 'creates only a single box object' do
              config = ActiveRecord::Base.remove_connection
              # Creating two concurrent requests from the same user
              # which tries to create two boxes simultaneously
              pids = [1,2].map do |i|
                name = params[:box][:name]
                # Create a new name so that we don't get validation errors
                params[:box][:name] = "#{name}-#{i}"
                fork_with_new_connection(config) { do_request(params) }
              end

              pids.each { |pid| Process.waitpid pid }
              ActiveRecord::Base.establish_connection(config)

              # Since the user runs out of N2O after the first request, the second box must not be created
              expect(user.reload.boxes.count).to eq(1)
            end
          end

          context 'when user has an active subscription' do
            before do
              plan = create :plan, cpu_multiplier: 2, vmem_multiplier: 3
              subscription = create :subscription,
                user: user,
                state: 'active',
                plan: plan

              expect {
                do_request(params)
              }.to change { Box.count }.by 1
            end

            it "should set the box's cpu_multiplier to that of his active subscription plan" do
              box = Box.last
              expect(box.name).to eq(params[:box][:name])

              expect(box.memory).to eq(1024)
              expect(box.virtual_memory).to eq(3072)
            end

            it "should set the box's virtual_memory to the subscription plan's vmem_multiplier * box's memory" do
              box = Box.last
              expect(box.name).to eq(params[:box][:name])

              expect(box.cpu_multiplier).to eq(2)
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
              expect(box.region).to eq(africa_region)
            end
          end

          context 'when "box_template" parameter is given instead of "box_template_id"' do
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
              expect(box.box_template).to eq(scala_box_template)
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
              it { expect(assigns(:box)).not_to be_persisted }
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
              it { expect(assigns(:box)).not_to be_persisted }
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
              it { expect(assigns(:box)).not_to be_persisted }
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
              it { expect(assigns(:box)).not_to be_persisted }
            end
          end

          context 'when there is a repository clone URL param' do
            before do
              params[:box][:repository] = {
                clone_url: 'https://github.com/rails/rails.git',
                state: 'identified',
                scm: 'git',
                file_to_open: 'README.nitrous.md'
              }
              allow(IncrementMixpanelPropertyJob).to receive(:submit_job).with(user.id, :repos_cloned, 1)
            end

            it 'creates a box and an associated repository' do
              expect {
                do_request(params)
              }.to change { Repository.count }.by 1

              box = Box.last
              repository = Repository.last
              expect(repository.box).to eql box
              expect(repository.clone_url).to eql 'https://github.com/rails/rails.git'
              expect(repository.state).to eql 'identified'
              expect(repository.scm).to eql 'git'
              expect(repository.file_to_open).to eql 'README.nitrous.md'
            end

            it 'tracks to Mixpanel' do
              expect(IncrementMixpanelPropertyJob).to receive(:submit_job).with(
                user.id,
                :repos_cloned,
                1
              )
              expect(TrackMixpanelEventJob).to receive(:submit_job).with(
                'Box Created',
                user.id,
                hash_including(cloned_repo: 'https://github.com/rails/rails.git')
              )
              do_request(params)
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
        end # when creating box from a box template

        context 'when creating box from a snapshot' do
          let!(:another_user) { create :user }
          let!(:another_box) { create :box, owner: another_user }
          let!(:snapshot) { create :snapshot, box: another_box, state: 'completed' }
          let(:params) { { box: { name: 'fragrant-wind-69', source_snapshot_id: snapshot.to_param, region_id: region.to_param, memory: 1024 } } }

          context 'when user has private snapshots feature enabled' do
            before do
              user.update_attribute :team_plans_enabled, true
              allow_any_instance_of(Box).to receive(:push_box_updated_message)
              allow_any_instance_of(Box).to receive(:coach).and_return(coach)
              coach.stub(:provision_box).and_return(true)
              allow(IncrementMixpanelPropertyJob).to receive(:submit_job)
              allow(TrackMixpanelEventJob).to receive(:submit_job)
            end

            context do
              before { do_request(params) }

              it { should respond_with :created }
              its('response.body') { should == Box.last.serialize_as_json }
            end

            it 'creates and persists a box with the given snapshot' do
              expect {
                do_request(params)
              }.to change { Box.count }.by 1

              box = Box.last
              expect(box.name).to eq(params[:box][:name])
              expect(box.region).to eq(region)
              expect(box.source_snapshot).to eq(snapshot)
              expect(box.box_template).to be_nil
              expect(box.users).to eq([user])
              expect(box.owner).to eq(user)
            end

            it 'should make a call to provision_box on coach' do
              expect(coach).to receive(:provision_box).and_return(true)
              do_request(params)
            end

            it 'tracks the relevant Mixpanel event and property' do
              expect(IncrementMixpanelPropertyJob).to receive(:submit_job).with(user.id, :boxes_created, 1)
              expect(TrackMixpanelEventJob).to receive(:submit_job).with('Box Created', user.id, hash_including(memory: an_instance_of(Fixnum), storage: an_instance_of(Fixnum), snapshot: snapshot.id, region: region.name))
              do_request(params)
            end

            context 'when a box template is also given' do
              let!(:box_template) { create :box_template, runtime: 'rails', enabled: true }

              before do
                params[:box].merge! box_template_id: box_template.to_param
              end

              it 'ignores the box template and creates a box from the snapshot' do
                expect {
                  do_request(params)
                }.to change { Box.count }.by 1

                box = Box.last
                expect(box.name).to eq(params[:box][:name])
                expect(box.source_snapshot).to eq(snapshot)
                expect(box.box_template).to be_nil
              end
            end
          end

          context 'when user does not have private snapshots feature enabled' do
            before { user.update_attribute :team_plans_enabled, false }

            it 'does not create a box' do
              expect {
                do_request(params)
              }.not_to change { Box.count }.by 1
            end

            context do
              before { do_request(params) }

              it { should respond_with :unprocessable_entity }
              it { expect(assigns(:box)).not_to be_persisted }
            end
          end
        end # when creating box from a snapshot
      end

      context 'with invalid params' do
        context 'with no params' do
          it 'does not create a box' do
            expect {
              do_request
            }.not_to change { Box.count }.by 1
          end

          context do
            before { do_request }

            it { should respond_with :unprocessable_entity }
            it { expect(assigns(:box)).not_to be_persisted }
          end
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
    it_behaves_like 'an action that returns 403 when user is delinquent'
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
    it_behaves_like 'an action that returns 403 when user is delinquent'
  end

  describe 'PUT update' do
    let(:another_user) { create :user }
    let!(:box1) { create :box, owner: user, memory: 384, storage: 750, state: 'running' }
    let!(:box2) { create :box, owner: another_user }
    let!(:default_params) { { id: box1.to_param, box: { memory: '512', storage: '1250' } } }

    before do
      create 'key_value', key: N2oAllocation::N2O_128MB_MEMORY,  value: 40
      create 'key_value', key: N2oAllocation::N2O_250MB_STORAGE, value: 10

      n2o_alloc = box1.n2o_allocations.build
      n2o_alloc.user = user
      n2o_alloc.kind = N2oAllocation::Kind::BOX_CREATION
      n2o_alloc.amount = box1.n2o_cost
      n2o_alloc.save!

      # Enough N2O for the upgrade
      user.fill_n2o! 250, N2oFill::Kind::FAVOR
    end

    def do_request(params=default_params)
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
              expect(TrackMixpanelEventJob).to receive(:submit_job).with('Box Configuration Upgraded', user.id)
              expect_any_instance_of(Box).to receive(:enqueue_reconfigure!).once
              do_request
            end

            it { should respond_with :success }
            its('response.body') { should == box1.reload.serialize_as_json }
          end

          context 'when there are concurrent requests to upgrade a box' do
            before do
              Box.any_instance.stub(:enqueue_reconfigure!)
            end

            it 'only reconfigures the box once' do
              # expect_any_instance_of(Box).to receive(:enqueue_reconfigure!).once
              config = ActiveRecord::Base.remove_connection
              # Creating two concurrent requests from the same user
              # which tries to create two boxes simultaneously
              pids = [1,2].map do |i|
                memory = default_params[:box][:memory]
                storage = default_params[:box][:storage]

                default_params[:box][:memory] = memory.to_i * i
                default_params[:box][:storage] = storage.to_i * i

                fork_with_new_connection(config) { do_request(default_params) }
              end

              pids.each { |pid| Process.waitpid pid }
              ActiveRecord::Base.establish_connection(config)

              # The second reconfigure will fail since the user will not have enough N2O
              expect(box1.reload.memory).to eq 512
              expect(box1.reload.storage).to eq 1250
            end
          end

          context "when user doesn't have enough n2o to upgrade the box" do
            before do
              user.n2o_fills.delete_all
              expect(TrackMixpanelEventJob).not_to receive(:submit_job)
              expect_any_instance_of(Box).to_not receive(:enqueue_reconfigure!)
              do_request
            end

            it { should respond_with :unprocessable_entity }
            its('response.body') { should == {errors: {base: ["Not enough N2O"]}}.to_json }
          end

          context "when user doesn't have n2o but downgrades the box" do
            before do
              user.n2o_fills.delete_all
              expect(TrackMixpanelEventJob).to receive(:submit_job).with('Box Configuration Downgraded', user.id)
              expect_any_instance_of(Box).to receive(:enqueue_reconfigure!).once
              do_request({ id: box1.to_param, box: { memory: '256', storage: '250' } })
            end

            it { should respond_with :success }
            its('response.body') { should == box1.reload.serialize_as_json }
          end
        end

        context 'when user has an active subscription' do
          before do
            expect(TrackMixpanelEventJob).to receive(:submit_job).with('Box Configuration Upgraded', user.id)
            expect_any_instance_of(Box).to receive(:enqueue_reconfigure!).once

            plan = create :plan, cpu_multiplier: 2, vmem_multiplier: 3
            subscription = create :subscription,
              user: user,
              state: 'active',
              plan: plan
          end

          it "should set the box's virtual_memory to the subscription plan's vmem_multiplier * box's memory" do
            do_request

            expect(box1.reload.virtual_memory).to eq(1536)
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

      it_behaves_like 'an action that returns 422 when the backend is not available', action: :enqueue_reconfigure!
    end

    it_behaves_like 'an action that returns 401 when not signed in'
    it_behaves_like 'an action that returns 403 when user is delinquent'
  end

  describe 'PUT auth' do
    let!(:box) { create :box }

    before { allow_any_instance_of(Coach).to receive(:update_auth).and_return nil }

    def do_request(params={})
      put :auth, { id: box.to_param, format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in box.owner }

      context 'when box exists' do
        it 'updates box auth username and password' do
          do_request box: { auth_username: 'admin', auth_password: 'password' }
          expect(box.reload.auth_username).to eq('admin')
          expect(box.reload.auth_password).to eq('password')
        end

        it 'fails when the box belongs to other user' do
          new_box = create :box
          expect {
            do_request id: new_box.to_param, box: { auth_username: 'admin', auth_password: 'password' }
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      it 'fails when the box does not exist' do
        expect {
          do_request id: '9001'
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
    it_behaves_like 'an action that returns 403 when user is delinquent'
  end

  describe 'PUT custom_domain' do
    let!(:box) { create :box }

    before { allow_any_instance_of(Coach).to receive(:update_custom_domain).and_return nil }

    def do_request(params={})
      put :custom_domain, { id: box.to_param, format: 'json' }.merge(params)
    end

    context 'when signed in' do
      before { sign_in box.owner }

      context 'when box exists' do
        it 'updates box custom domain' do
          expect {
            do_request box: { custom_domain: 'wtf.com' }
          }.to change { box.reload.custom_domain }.to('wtf.com')
        end

        it 'fails when the box belongs to other user' do
          new_box = create :box
          expect {
            do_request id: new_box.to_param, box: { custom_domain: 'lala.com' }
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end

      it 'fails when the box does not exist' do
        expect {
          do_request id: '9001'
        }.to raise_error ActiveRecord::RecordNotFound
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
    it_behaves_like 'an action that returns 403 when user is delinquent'
  end

  describe 'PUT clone_repo' do
    let!(:box) { create :box }

    def do_request(repo_params={})
      put :clone_repo, { id: box.to_param, format: 'json', repository: { clone_url: 'https://github.com/nitrous-io/autoparts', scm: 'git', state: 'identified', file_to_open: 'README.nitrous.md'}.merge(repo_params) }
    end

    context 'when signed in' do
      before do
        allow_any_instance_of(Box).to receive(:push_box_updated_message).and_return nil
        sign_in box.owner
      end

      context 'when box is running' do
        before { box.update_attribute :state, 'running' }

        it 'creates a new repository with the right attributes' do
          expect {
            do_request
          }.to change(box.reload.repositories, :count).by(1)

          repo = box.repositories.last
          expect(repo.clone_url).to eql 'https://github.com/nitrous-io/autoparts'
          expect(repo.scm).to eql 'git'
          expect(repo.file_to_open).to eql 'README.nitrous.md'
        end

        it 'changes the state of the box to be "cloning_repo"' do
          expect {
            do_request
            box.reload
          }.to change(box, :state).from('running').to('cloning_repo')
        end

        it 'initiates cloning of the repository if it is identified' do
          do_request
          repository = box.reload.repositories.last
          expect(repository.state).to eql 'cloning'
        end

        it 'tracks the cloning of the repo on Mixpanel' do
          expect(TrackMixpanelEventJob).to receive(:submit_job).with(
            'Repo Cloned',
            box.owner.id,
            box: box.id,
            clone_url: 'https://github.com/nitrous-io/autoparts'
          )
          expect(IncrementMixpanelPropertyJob).to receive(:submit_job).with(
            box.owner.id,
            :repos_cloned,
            1
          )
          do_request
        end
      end

      context 'when box is stopped' do
        before { box.update_attribute :state, 'stopped' }

        it 'creates a new repository' do
          expect {
            do_request
          }.to change(box.reload.repositories, :count).by(1)

          repo = box.repositories.last
          expect(repo.clone_url).to eql 'https://github.com/nitrous-io/autoparts'
          expect(repo.scm).to eql 'git'
          expect(repo.file_to_open).to eql 'README.nitrous.md'
        end

        it 'changes the state of the box to be "cloning_repo"' do
          expect {
            do_request
            box.reload
          }.to change(box, :state).from('stopped').to('starting')
        end

        it 'does not initiate cloning of the repository' do
          # since it will be handled upon start
          do_request
          repository = box.reload.repositories.last
          expect(repository.state).to eql 'identified'
        end

        it 'tracks the cloning of the repo on Mixpanel' do
          expect(TrackMixpanelEventJob).to receive(:submit_job).with(
            'Repo Cloned',
            box.owner.id,
            box: box.id,
            clone_url: 'https://github.com/nitrous-io/autoparts'
          )
          expect(IncrementMixpanelPropertyJob).to receive(:submit_job).with(
            box.owner.id,
            :repos_cloned,
            1
          )
          do_request
        end
      end

      context 'when box is in a dangling state' do
        before { box.update_attribute :state, 'starting' }

        it 'does not create a new repository' do
          expect {
            do_request
          }.to_not change(box.reload.repositories, :count)
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
    it_behaves_like 'an action that returns 403 when user is delinquent'
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
            expect(IncrementMixpanelPropertyJob).to receive(:submit_job).with(user.id, :boxes_terminated, 1)
            expect(TrackMixpanelEventJob).to receive(:submit_job).with('Box Terminated', user.id)

            expect_any_instance_of(Box).to receive(:enqueue_terminate!).once
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
          it { expect(assigns(:box)).to eq(box1) }
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
    it_behaves_like 'an action that returns 403 when user is delinquent'
  end

  shared_examples 'a box control action that tracks mixpanel properties and events' do |options|
    action = options[:action]
    previous_state = options[:previous_state]
    additional_params = options[:params] || {}
    mixpanel_event = options[:mixpanel_event]
    mixpanel_property = options[:mixpanel_property]
    mixpanel_value = options[:mixpanel_value]

    let!(:box) { create :box, owner: user, state: previous_state }

    define_method :do_request do |params={}|
      put action, { format: 'json' }.merge(params).merge(additional_params)
    end

    before do
      sign_in user
      allow_any_instance_of(Box).to receive(:"enqueue_#{action}!")
    end

    it 'should start the expected jobs' do
      if mixpanel_property.present?
        expect(IncrementMixpanelPropertyJob).to receive(:submit_job).with(user.id, mixpanel_property, mixpanel_value)
      end
      expect(TrackMixpanelEventJob).to receive(:submit_job).with(mixpanel_event, user.id)
      do_request id: box.to_param
    end
  end

  shared_examples 'a box control action' do |options|
    action = options[:action]
    previous_state = options[:previous_state]
    additional_params = options[:params] || {}

    let(:another_user) { create :user }
    let!(:box1) { create :box, owner: user, state: previous_state }
    let!(:box2) { create :box, owner: another_user, state: previous_state }

    define_method :do_request do |params={ id: box1.to_param }|
      put action, { format: 'json' }.merge(params).merge(additional_params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when a valid id is given' do
        context 'when the box belongs to the current user' do
          let(:params) { { id: box1.to_param } }

          before do
            allow_any_instance_of(Box).to receive(:"enqueue_#{action}!")
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
    it_behaves_like 'an action that returns 403 when user is delinquent'
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
      allow_any_instance_of(Box).to receive(:push_box_updated_message).and_return nil

      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(ENV['WEBHOOK_USERNAME'], ENV['WEBHOOK_PASSWORD'])
    end

    def do_request(payload)
      put :webhook, id: box.to_param, payload: payload
    end

    context 'when an aio:created message is received' do
      let!(:coach) { instance_double('Coach') }

      before do
        allow_any_instance_of(Box).to receive(:coach).and_return coach
        coach.stub(:start_box).and_return(true)
        box.update_attribute(:state, 'provisioning')
      end

      context 'successful creation' do
        it 'should start the box' do
          expect(coach).to receive(:start_box).and_return(true)

          do_request('{"type":"aio:created","success":true,"port":10000,"id":"apse1-1.actionbox.io"}')

          expect(box.reload.host).to eq('apse1-1.actionbox.io')
          expect(box.port).to eq(10000)
          expect(box.state).to eq('starting')

          expect(response.status).to eq(200)
          expect(response.body).to eq({status: 'ok'}.to_json)
        end
      end

      context 'unsuccessful creation' do
        it 'should NOT make a call to the coach to start the box, but transition from provisioning to failed' do
          expect(coach).not_to receive(:start_box)

          do_request('{"type":"aio:created","success":false}')

          expect(box.reload.state).to eq('failed')
          expect(response.status).to eq(200)
          expect(response.body).to eq({status: 'ok'}.to_json)
        end
      end
    end

    context 'when an aio:started message is received' do
      context 'when box is starting' do
        before { box.update_attribute(:state, 'starting') }

        it 'should change the state of the box from starting to running' do
          stub_const('Box::BASE_CPU_SHARES', 512)

          do_request('{"type":"aio:started","boxId":1,"name":"rails-box","data":{"memory":640,"virtualMemory":1280,"cpuShares":1024}}')

          expect(box.reload.state).to eq('running')
          expect(box.reload.memory).to eq(640)
          expect(box.reload.virtual_memory).to eq(1280)
          expect(box.reload.cpu_multiplier).to eq(2)
          expect(response.status).to eq(200)
          expect(response.body).to eq({status: 'ok'}.to_json)
        end
      end

      context 'when there is a repository to clone' do
        let!(:repository) { create :repository, box: box, state: 'identified', scm: 'git' }

        before do
          box.update_attribute :state, 'starting'
        end

        it 'should initiate cloning of the repository' do
          do_request('{"type":"aio:started","boxId":1,"name":"rails-box","data":{"memory":640,"virtualMemory":1280,"cpuShares":1024}}')

          expect(box.reload.state).to eq('cloning_repo')
          expect(box.reload.memory).to eq(640)
          expect(box.reload.virtual_memory).to eq(1280)
          expect(box.reload.cpu_multiplier).to eq(2)
          expect(response.status).to eq(200)

          expect(box.last_added_repository).to eql repository # Just an assertion.
          expect(repository.reload.state).to eql 'cloning'

          expect(response.body).to eq({status: 'ok'}.to_json)
        end
      end

      context 'when box is already running' do
        before do
          box.update_attribute(:memory, 512)
          box.update_attribute(:state, 'running')
        end

        it 'should not try to start the box nor update its specs' do
          do_request('{"type":"aio:started","boxId":1,"name":"rails-box","data":{"memory":640,"virtualMemory":1280,"cpuShares":1024}}')

          expect(box.reload.state).to eq('running')
          expect(box.reload.memory).to eq(512)

          expect(response.status).to eq(200)
          expect(response.body).to eq({status: 'ok'}.to_json)
        end
      end

      context 'when box is neither starting nor running' do
        before do
          box.update_attribute(:state, 'stopped')
          do_request('{"type":"aio:started","boxId":1,"name":"rails-box","data":{"memory":640,"virtualMemory":1280,"cpuShares":1024}}')
        end

        it "should not change the box's state" do
          expect(box.reload.state).to eq('stopped')
          expect(response.body).to eq({status: 'Invalid box transition'}.to_json)
        end

        it { should respond_with :conflict }
      end
    end

    context 'when an aio:stopped message is received' do
      context 'when box is stopping' do
        before { box.update_attribute(:state, 'stopping') }

        it 'should change the state of the box from stopping to stopped' do
          do_request('{"type":"aio:stopped","boxId":1,"name":"rails-box"}')

          expect(box.reload.state).to eq('stopped')
          expect(response.status).to eq(200)
          expect(response.body).to eq({status: 'ok'}.to_json)
        end
      end

      context 'when box is stopped' do
        before { box.update_attribute(:state, 'stopped') }

        it 'should not try to stop the box' do
          do_request('{"type":"aio:stopped","boxId":1,"name":"rails-box"}')

          expect(box.reload.state).to eq('stopped')
          expect(response.status).to eq(200)
          expect(response.body).to eq({status: 'ok'}.to_json)
        end
      end

      context 'when box is neither stopping nor stopped' do
        before do
          box.update_attribute(:state, 'running')
          do_request('{"type":"aio:stopped","boxId":1,"name":"rails-box"}')
        end

        it "should not change the box's state" do
          expect(box.reload.state).to eq('running')
          expect(response.body).to eq({status: 'Invalid box transition'}.to_json)
        end

        it { should respond_with :conflict }
      end
    end

    context 'when an aio:restarted message is received' do
      context 'when box is restarting' do
        before { box.update_attribute(:state, 'restarting') }

        it 'should change the state of the box from restarting to running' do
          stub_const('Box::BASE_CPU_SHARES', 512)

          do_request('{"type":"aio:restarted","boxId":1,"name":"rails-box","data":{"memory":640,"virtualMemory":1280,"cpuShares":1024}}')

          expect(box.reload.state).to eq('running')
          expect(box.reload.memory).to eq(640)
          expect(box.reload.virtual_memory).to eq(1280)
          expect(box.reload.cpu_multiplier).to eq(2)
          expect(response.status).to eq(200)
          expect(response.body).to eq({status: 'ok'}.to_json)
        end
      end

      context 'when box is already running' do
        before do
          box.update_attribute(:memory, 512)
          box.update_attribute(:state, 'running')
        end

        it 'should not try to restart the box nor update its specs' do
          do_request('{"type":"aio:restarted","boxId":1,"name":"rails-box","data":{"memory":640,"virtualMemory":1280,"cpuShares":1024}}')

          expect(box.reload.state).to eq('running')
          expect(box.reload.memory).to eq(512)

          expect(response.status).to eq(200)
          expect(response.body).to eq({status: 'ok'}.to_json)
        end
      end

      context 'when box is neither restarting nor running' do
        before do
          box.update_attribute(:state, 'stopped')
          do_request('{"type":"aio:restarted","boxId":1,"name":"rails-box","data":{"memory":640,"virtualMemory":1280,"cpuShares":1024}}')
        end

        it "should not change the box's state" do
          expect(box.reload.state).to eq('stopped')
          expect(response.body).to eq({status: 'Invalid box transition'}.to_json)
        end

        it { should respond_with :conflict }
      end
    end

    context 'when an aio:destroyed message is received' do
      context 'when box is terminating' do
        before { box.update_attribute(:state, 'terminating') }

        it 'should change the state of the box from terminating to terminated' do
          do_request('{"type":"aio:destroyed","boxId":1,"name":"rails-box"}')

          expect(box.reload.state).to eq('terminated')
          expect(response.status).to eq(200)
          expect(response.body).to eq({status: 'ok'}.to_json)
        end

        context 'when box owner is deleted' do
          before { box.update_attribute :owner_id, nil }

          it 'should change the state of the box from terminating to terminated' do
            do_request('{"type":"aio:destroyed","boxId":1,"name":"rails-box"}')

            expect(box.reload.state).to eq('terminated')
            expect(response.status).to eq(200)
            expect(response.body).to eq({status: 'ok'}.to_json)
          end
        end
      end

      context 'when box is already terminated' do
        before { box.update_attribute(:state, 'terminated') }

        it 'should not try to terminate the box' do
          do_request('{"type":"aio:destroyed","boxId":1,"name":"rails-box"}')

          expect(box.reload.state).to eq('terminated')
          expect(response.status).to eq(200)
          expect(response.body).to eq({status: 'ok'}.to_json)
        end
      end

      context 'when box is neither terminating nor terminated' do
        before do
          box.update_attribute(:state, 'running')
          do_request('{"type":"aio:destroyed","boxId":1,"name":"rails-box"}')
        end

        it "should not change the box's state" do
          expect(box.reload.state).to eq('running')
          expect(response.body).to eq({status: 'Invalid box transition'}.to_json)
        end

        it { should respond_with :conflict }
      end
    end

    context 'when an aio:snapshotted message is received' do
      let!(:initiated_snapshot) { create :snapshot, id: 23, box: box, state: 'initiated' }

      context 'when box is snapshotting' do
        before { box.update_attribute(:state, 'snapshotting') }

        context "when the snapshot ID in the message matches that of the box's initiated snapshot" do

          context 'when the message reports a successful snapshot' do
            let!(:message) { '{"type":"aio:snapshotted","boxId":1,"snapshotId":23,"snapshotUrl":"s3://snapshots-bucket/snapshot-23.tar.gz","snapshotSize":69,"name":"rails-box","success":true}' }

            it 'should change the state of the box to stopped' do
              do_request message

              expect(box.reload.state).to eq('stopped')
              expect(response.status).to eq(200)
              expect(response.body).to eq({status: 'ok'}.to_json)
            end

            it 'should change its initiated snapshot to the completed state' do
              do_request message
              expect(initiated_snapshot.reload.state).to eql 'completed'
            end

            it "should set its initiated snapshot's URL to the snapshotUrl in the message" do
              do_request message
              expect(initiated_snapshot.reload.url).to eql 's3://snapshots-bucket/snapshot-23.tar.gz'
            end

            it "should set its initiated snapshot's size to the snapshotSize in the message" do
              do_request message
              expect(initiated_snapshot.reload.size).to eql 69
            end
          end

          context 'when the message reports an unsuccessful snapshot' do
            let!(:message) { '{"type":"aio:snapshotted","boxId":1,"snapshotId":23,"name":"rails-box","success":false}' }

            it 'should change the state of the box to stopped' do
              do_request message

              expect(box.reload.state).to eq('stopped')
              expect(response.status).to eq(200)
              expect(response.body).to eq({status: 'ok'}.to_json)
            end

            it 'should change its initiated snapshot to the failed state' do
              do_request message
              expect(initiated_snapshot.reload.state).to eql 'failed'
            end
          end
        end

        context "when the snapshot ID in the message does not match that of the box's initiated snapshot" do
          let!(:message) { '{"type":"aio:snapshotted","boxId":1,"snapshotId":"wtf-ID","name":"rails-box","success":true}' }

          it 'should not change the state of the box' do
            do_request message

            expect(box.reload.state).to eq('snapshotting')
            expect(response.status).to eq(200)
            expect(response.body).to eq({status: 'ok'}.to_json)
          end

          it 'should not change its initiated snapshot to the completed state' do
            do_request message
            expect(initiated_snapshot.reload.state).to eql 'initiated'
          end
        end
      end

      context 'when box is already stopped' do
        before { box.update_attribute(:state, 'stopped') }

        it 'should not try to snapshot the box' do
          do_request('{"type":"aio:snapshotted","boxId":1,"snapshotId":23,"name":"rails-box","success":true}')

          expect(box.reload.state).to eq('stopped')
          expect(response.status).to eq(200)
          expect(response.body).to eq({status: 'ok'}.to_json)
        end
      end
    end

    context 'when an aio:cloned_repository message is received' do
      before do
        box.update_attribute :state, 'cloning_repo'
        allow(TrackMixpanelEventJob).to receive(:submit_job)
      end

      context 'when there is a repository being cloned that matches the url in the message' do
        let!(:repository) { create :repository, box: box, scm: 'git', state: 'cloning', clone_url: 'https://github.com/rails/rails.git' }

        context 'when the message indicates success' do
          let!(:message) { JSON.dump({
            type: 'aio:cloned_repository',
            boxId: 1,
            success: true,
            repositoryUrl:'https://github.com/rails/rails.git'
          }) }

          it 'sets the repository to the cloned state' do
            do_request(message)
            expect(repository.reload.state).to eql 'cloned'
            expect(response.status).to eq(200)
            expect(response.body).to eq({status: 'ok'}.to_json)
          end

          it 'sets the box to the "running" state' do
            expect {
              do_request(message)
              box.reload
            }.to change(box, :state).from('cloning_repo').to('running')
          end

          it 'tracks the event in Mixpanel' do
            expect(TrackMixpanelEventJob).to receive(:submit_job).with(
              'Repo Cloning Succeeded',
              box.owner.id,
              box: box.id,
              clone_url: 'https://github.com/rails/rails.git'
            )
            do_request(message)
          end
        end

        context 'when the message indicates failure' do
          let(:message) { JSON.dump({
            type: 'aio:cloned_repository',
            boxId: 1,
            success: false,
            error: 'no disk space',
            repositoryUrl:'https://github.com/rails/rails.git'
          }) }

          it 'sets the repository to the failed state' do
            do_request(message)
            repository.reload
            expect(repository.state).to eql 'failed'
            expect(repository.failure_reason).to eql 'no disk space'
            expect(response.status).to eq(200)
            expect(response.body).to eq({status: 'ok'}.to_json)
          end

          it 'sets the box to the "running" state' do
            expect {
              do_request(message)
              box.reload
            }.to change(box, :state).from('cloning_repo').to('running')
          end

          it 'tracks the event in Mixpanel' do
            expect(TrackMixpanelEventJob).to receive(:submit_job).with(
              'Repo Cloning Failed',
              box.owner.id,
              box: box.id,
              clone_url: 'https://github.com/rails/rails.git'
            )
            do_request(message)
          end
        end
      end
    end

    context 'when an aio:configured message is received' do
      context 'when configured message dataType is aio:configured:change_specs' do
        context 'when box is already running' do
          before do
            box.update_attribute(:memory, 512)
            box.update_attribute(:state, 'running')
          end

          it 'reconfigures the box and updates its specs' do
            do_request('{"type":"aio:configured","boxId":1,"dataType":"aio:configured:change_specs","data":{"memory":384,"diskSpace":750,"virtualMemory":768,"cpuShares":1024}}')

            expect(box.reload.state).to eq('running')
            expect(box.reload.memory).to eq(512)

            expect(response.status).to eq(200)
            expect(response.body).to eq({status: 'ok'}.to_json)
          end
        end

        context 'when box is stopped' do
          before do
            box.update_attribute(:state, 'stopped')
            do_request('{"type":"aio:configured","boxId":1,"dataType":"aio:configured:change_specs","data":{"memory":384,"diskSpace":750,"virtualMemory":768,"cpuShares":1024}}')
          end

          it "should not change the box's state" do
            expect(box.reload.state).to eq('stopped')
            expect(response.status).to eq(200)
            expect(response.body).to eq({status: 'ok'}.to_json)
          end
        end
      end
    end

    context 'when an aio:info_response message is received' do
      let(:channel) { double.as_null_object }

      it 'should send a message via websockets with the box info' do
        expect(Shover).to receive(:publish).with(box.owner.id, 'aio:box_info_response', {box: { id: box.id, memory_usage: 256, storage_usage: 1000, lxc_status: 'RUNNING' }})

        expect(Pusher).to receive(:[]).with("private-user-#{box.owner.id}") { channel }
        expect(channel).to receive(:trigger) do |message, data|
          expect(message).to eq 'aio:box_info_response'
          expect(data).to eq({box: { id: box.id, memory_usage: 256, storage_usage: 1000, lxc_status: 'RUNNING' }}.to_json)
        end

        do_request('{"type":"aio:info_response","boxId":1,"name":"rails-box","info":{"memoryUsage":256,"storageUsage":1000,"lxcStatus":"RUNNING"}}')

        expect(response.status).to eq(200)
        expect(response.body).to eq({status: 'ok'}.to_json)
      end
    end

    context 'when an aio:migrated message is received' do
      before { box.update_attribute :state, "migrating" }

      context 'successful migration' do
        it 'updates the state of the box' do
          do_request('{"type":"aio:migrated","success":true}')
          expect(box.reload.state).to eq("stopped")
          expect(response.body).to eq({status: 'ok'}.to_json)
        end
      end

      context 'unsuccessful creation' do
        it 'does not update the box' do
          do_request('{"type":"aio:migrated","success":false}')
          expect(box.reload.state).to eq("migrating")
          expect(response.body).to eq({status: 'ok'}.to_json)
        end
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
        expect(IncrementMixpanelPropertyJob).to receive(:submit_job).with(user.id, :public_keys_added_to_github, 1)
        expect(TrackMixpanelEventJob).to receive(:submit_job).with('Github Added Key', user.id)

        expect {
          do_request id: box1.to_param
        }.to change { Delayed::Job.count }.by(1)
        expect(response).to be_success
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
    it_behaves_like 'an action that returns 403 when user is delinquent'
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

        expect(response).to be_success
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
    it_behaves_like 'an action that returns 403 when user is delinquent'
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

        expect(response).to be_success
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
    it_behaves_like 'an action that returns 403 when user is delinquent'
  end

  describe 'POST touch' do
    let!(:box) { create :box, touched_at: 1.day.ago }

    def do_request(params={})
      post :touch, { id: box.to_param }.merge(params)
    end

    context 'when box exists' do
      context 'when event param is empty' do
        it "tracks ssh sessions started, number of ssh session started, and box heartbeat and updates touched_at and last_heartbeat_tracked_at" do
          expect(TrackMixpanelEventJob).to receive(:submit_job).with 'SSH Session Started', box.owner.id
          expect(TrackMixpanelEventJob).to receive(:submit_job).with 'Box Heartbeat', box.owner.id
          expect(IncrementMixpanelPropertyJob).to receive(:submit_job).with(box.owner.id, :ssh_sessions_started, 1)

          Timecop.freeze do
            do_request
            expect(controller).to respond_with :success
            expect(response.body).to eq({status: 'ok'}.to_json)
            box.reload
            expect(box.touched_at.to_i).to eq(Time.zone.now.to_i)
            expect(box.last_heartbeat_tracked_at.to_i).to eq(Time.zone.now.to_i)
          end
        end

        context 'when last_heartbeat_tracked_at is less than 15 minutes ago' do
          it 'still tracks box heartbeat' do
            expect(TrackMixpanelEventJob).to receive(:submit_job).with 'SSH Session Started', box.owner.id
            expect(TrackMixpanelEventJob).to receive(:submit_job).with 'Box Heartbeat', box.owner.id
            expect(IncrementMixpanelPropertyJob).to receive(:submit_job).with(box.owner.id, :ssh_sessions_started, 1)

            Timecop.freeze do
              box.last_heartbeat_tracked_at = 15.minutes.ago + 1.second
              box.save!
              do_request
              expect(controller).to respond_with :success
              expect(response.body).to eq({status: 'ok'}.to_json)
              box.reload
              expect(box.touched_at.to_i).to eq(Time.zone.now.to_i)
              expect(box.last_heartbeat_tracked_at.to_i).to eq(Time.zone.now.to_i)
            end
          end
        end
      end

      context 'when event param is heartbeat' do
        context 'when last_heartbeat_tracked_at is null' do
          it "tracks box heartbeat and updates touched_at and last_heartbeat_tracked_at" do
            expect(TrackMixpanelEventJob).to receive(:submit_job).once.with 'Box Heartbeat', box.owner.id

            Timecop.freeze do
              do_request event: 'heartbeat'
              expect(controller).to respond_with :success
              expect(response.body).to eq({status: 'ok'}.to_json)
              box.reload
              expect(box.touched_at.to_i).to eq(Time.zone.now.to_i)
              expect(box.last_heartbeat_tracked_at.to_i).to eq(Time.zone.now.to_i)
            end
          end
        end

        context 'when last_heartbeat_tracked_at is greater than or equal to 15 minutes ago' do
          it "tracks box heartbeat and updates touched_at and last_heartbeat_tracked_at" do
            expect(TrackMixpanelEventJob).to receive(:submit_job).once.with 'Box Heartbeat', box.owner.id

            Timecop.freeze do
              box.last_heartbeat_tracked_at = 30.minutes.ago
              box.save!
              do_request event: 'heartbeat'
              expect(controller).to respond_with :success
              expect(response.body).to eq({status: 'ok'}.to_json)
              box.reload
              expect(box.touched_at.to_i).to eq(Time.zone.now.to_i)
              expect(box.last_heartbeat_tracked_at.to_i).to eq(Time.zone.now.to_i)
            end
          end
        end

        context 'when last_heartbeat_tracked_at is less than 15 minutes ago' do
          it "does not track box heartbeat and does not update last_heartbeat_tracked_at but updates touched_at" do
            expect(TrackMixpanelEventJob).not_to receive(:submit_job)

            Timecop.freeze do
              box.last_heartbeat_tracked_at = 15.minutes.ago + 1.second
              box.save!
              expect {
                do_request event: 'heartbeat'
              }.not_to change { box.reload.last_heartbeat_tracked_at }
              expect(controller).to respond_with :success
              expect(response.body).to eq({status: 'ok'}.to_json)
              box.reload
              expect(box.touched_at.to_i).to eq(Time.zone.now.to_i)
            end
          end
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

  describe 'POST track_preview' do
    let!(:box) { create :box }

    def do_request(params={})
      post :track_preview, { id: box.to_param }.merge(params)
    end

    context 'when box exists' do
      it "tracks preview url visited" do
        expect(TrackMixpanelEventJob).to receive(:submit_job).with 'Preview URL Visited', box.owner.id

        do_request
        expect(controller).to respond_with :success
        expect(response.body).to eq({status: 'ok'}.to_json)
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
