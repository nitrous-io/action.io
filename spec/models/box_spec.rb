# coding: utf-8

require 'spec_helper'

describe Box do
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :memory }
  it { should allow_mass_assignment_of :storage }
  it { should_not allow_mass_assignment_of :host }
  it { should_not allow_mass_assignment_of :port }
  it { should_not allow_mass_assignment_of :tty_port }
  it { should_not allow_mass_assignment_of :state }
  it { should_not allow_mass_assignment_of :key }
  it { should_not allow_mass_assignment_of :box_template_id }
  it { should_not allow_mass_assignment_of :owner_id }
  it { should_not allow_mass_assignment_of :region_id }

  it { should have_many(:box_users).dependent(:destroy) }
  it { should have_many(:key_pairs).dependent(:destroy) }
  it { should have_many(:box_limit_hit_events).dependent(:destroy) }
  it { should have_many(:users).through(:box_users) }
  it { should have_many(:n2o_allocations) }

  it { should belong_to(:box_template) }
  it { should belong_to(:owner).class_name('User') }
  it { should belong_to(:region) }

  describe '#create' do
    let(:region) { create :region, version: "v666", enabled: true }

    it 'saves the current supported version as box attribute' do
      box = create :box, region: region
      box.version.should eq("v666")
    end
  end

  describe 'validations' do
    let!(:box) { create :box }

    it { should validate_presence_of(:owner_id) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:region_id) }
    it { should validate_presence_of(:box_template_id) }
    it { should validate_presence_of(:memory) }
    it { should validate_presence_of(:storage) }

    it { should validate_uniqueness_of(:name).scoped_to(:owner_id) }
    it { should ensure_length_of(:name).is_at_least(4).is_at_most(40) }

    it { should allow_value('fragrant-wind-69').for(:name) }
    it { should allow_value('fragrantwind69').for(:name) }
    it { should_not allow_value('fr@gr@nt-w|nd-69').for(:name) }
    it { should_not allow_value('fragrant_wind_69').for(:name) }
    it { should_not allow_value('69-fragrant-wind').for(:name) }
    it { should_not allow_value('-fragrant-wind-69').for(:name) }
    it { should_not allow_value('fragrant-wind-69-').for(:name) }
    it { should_not allow_value('fragrant wind 69').for(:name) }
    it { should_not allow_value('향기로운-바람-69').for(:name) }

    describe 'availability of a name', focus: true do
      let!(:user) { create :user }
      let(:box)   { build :box, name: 'foo-box', owner: user }

      context 'when there is a terminated box with the same name' do
        before do
          create :box, name: 'foo-box', owner: user, state: 'terminated'
        end

        it 'should be valid' do
          expect(box).to be_valid
        end
      end

      context 'when there is a running box with the same name' do
        before do
          create :box, name: 'foo-box', owner: user, state: 'running'
        end

        it 'should not be valid' do
          expect(box).not_to be_valid
        end
      end
    end

    describe 'memory' do
      let!(:user) { create :user }
      let(:box)   { build :box, owner: user, memory: 384, storage: 750 }

      before do
        create :key_value, key: Box::N2O_MIN_MEMORY_MB,  value: 384
        create :key_value, key: Box::N2O_MAX_MEMORY_MB,  value: 2048
      end

      context 'when memory of the box is too high' do
        it 'should not be valid' do
          box.memory = 3072
          expect(box).not_to be_valid
        end
      end

      context 'when memory of the box is just right' do
        it 'should be valid' do
          box.memory = 1024
          expect(box).to be_valid
        end
      end
    end

    describe 'storage' do
      let!(:user) { create :user }
      let(:box)   { build :box, owner: user, memory: 384, storage: 750 }

      before do
        create :key_value, key: Box::N2O_MIN_STORAGE_MB,  value: 250
        create :key_value, key: Box::N2O_MAX_STORAGE_MB,  value: 10000
      end

      context 'when storage of the box is too high' do
        it 'should not be valid' do
          box.storage = 12000
          expect(box).not_to be_valid
        end
      end

      context 'when storage of the box is just right' do
        it 'should be valid' do
          box.memory = 1000
          expect(box).to be_valid
        end
      end
    end

    describe 'n2o check' do
      let(:box) { create :box }

      context 'when n2o_allocation_needed? is true' do
        before { box.stub(:n2o_allocation_needed?).and_return true }

        it 'checks whether there is sufficient free n2o' do
          box.should_receive :validate_free_n2o
          box.valid?
        end
      end

      context 'when n2o_allocation_needed? is false' do
        before { box.stub(:n2o_allocation_needed?).and_return false }

        it 'does not check whether there is sufficient free n2o' do
          box.should_not_receive :validate_free_n2o
          box.valid?
        end
      end
    end

    context 'region is not available' do
      let!(:unavailable_region) { create :region, enabled: true, state: 'down' }

      context 'when owner is not an admin' do
        let!(:non_admin_user) { create :user }

        it 'adds an error on region' do
          new_box = build :box, owner: non_admin_user, region: unavailable_region
          new_box.valid?
          expect(new_box).to have(1).error_on(:region_id)
        end
      end

      context 'when owner is an admin' do
        let!(:admin_user) { create :admin }

        it 'do not add any errors on region' do
          new_box = build :box, owner: admin_user, region: unavailable_region
          new_box.valid?

          expect(new_box).to have(:no).errors_on(:region_id)
        end
      end

      it 'does not affect saving exisiting boxes' do
        box.region = unavailable_region
        box.should be_valid
      end
    end
  end

  describe 'scopes' do
    let!(:box_1) { create :box                         }
    let!(:box_2) { create :box, state: 'terminated'    }
    let!(:box_3) { create :box, state: 'running'       }
    let!(:box_4) { create :box, state: 'starting'      }
    let!(:box_5) { create :box, state: 'stopping'      }
    let!(:box_6) { create :box, state: 'provisioning'  }

    describe '.unterminated' do
      it "should return all boxes which don't have the state set to 'terminated'" do
        Box.unterminated.to_a.should =~ [box_1, box_3, box_4, box_5, box_6]
      end
    end

    describe '.running' do
      it "should return all boxes which don't have the state set to 'terminated'" do
        Box.running.to_a.should == [box_3]
      end
    end

    describe '.dangling' do
      it "should return all boxes which are either born, provisioning, starting, stopping" do
        Box.dangling.to_a.should =~ [box_1, box_4, box_5, box_6]
      end
    end

    describe '.idle' do
      it 'returns all running boxes which are not touched in specified duration' do
        box_3.update_attribute :touched_at, 1.month.ago
        Box.idle(1.hour.ago).should =~ [box_3]
        box_3.update_attribute :touched_at, 1.minute.ago
        Box.idle(1.hour.ago).should be_empty
      end
    end
  end

  describe 'delegates' do
    let!(:region_1) { create :region, box_server_uri: 'https://boxserver.example.com:1234', enabled: true }
    let!(:box_1)    { create :box, region: region_1 }

    describe "box_server_uri" do
      it "should return the box server uri of the region that it belongs to" do
        box_1.box_server_uri.should == 'https://boxserver.example.com:1234'
      end
    end
  end

  context 'before validation' do
    let!(:box) { build :box, name: 'Fragrant-Wind-69' }

    it 'downcases name' do
      box.valid?
      box.name.should == 'fragrant-wind-69'
    end

    it 'rounds down memory and storage' do
      box.should_receive :round_down_memory_and_storage
      box.valid?
    end
  end

  context 'before create' do
    it 'adds owner to users' do
      user = create :user
      box = create :box, owner: user
      box.users.should == [user]
    end
  end

  context 'after save' do
    let!(:box) { create :box }

    context 'when n2o_delta is positive' do
      before do
        box.stub(:n2o_delta).and_return 200
      end

      it 'invokes allocate_n2o! after saving' do
        box.should_receive :allocate_n2o!
        box.save
      end
    end

    context 'when n2o_delta is negative' do
      before { box.stub(:n2o_delta).and_return(-200) }

      it 'invokes allocate_n2o! after saving' do
        box.should_receive :allocate_n2o!
        box.save
      end
    end

    context 'when n2o_delta is zero' do
      before { box.stub(:n2o_delta).and_return(0) }

      it 'does not invoke allocate_n2o! after saving' do
        box.should_not_receive :allocate_n2o!
        box.save
      end
    end
  end

  context 'after create' do
    it 'creates a key pair for the box' do
      box = build :box
      box.should_receive(:generate_key_pair)
      box.save
    end
  end

  describe '#coach' do
    it 'memoizes and returns a new Coach instance' do
      mock_coach = double('coach')
      Box.any_instance.stub(:enqueue_provision!)

      box = create :box

      Coach.stub(:new) do |_box|
        _box.should == box
        mock_coach
      end

      coach = box.coach
      coach.should == mock_coach
      box.instance_variable_get(:@coach).should == mock_coach
    end
  end

  describe 'state machine' do
    let(:box_template)  { create :box_template, image: 'rails' }
    let!(:mock_coach)   { double('coach') }
    let!(:box)          { create :box }

    before { box.stub!(:coach) { mock_coach } }

    describe '#orphan' do
      before { box.update_attribute :state, 'provisioning' }

      it 'changes the state to failed' do
        box.should_receive :push_box_updated_message

        expect {
          box.orphan!
        }.to change(box, :state).from('provisioning').to('failed')
      end

      it 'sends an email to notify of the failure' do
        box.should_receive :push_box_updated_message

        expect {
          box.orphan!
        }.to change(Delayed::Job, :count).by(1)

        Delayed::Job.first.handler.should =~ /'Notifier'\nmethod_name: :box_provisioning_failed\nargs:\n- #{box.id}\n/
      end
    end

    describe '#enqueue_provision' do
      it 'calls the Coach API to to provision a box' do
        mock_coach.should_receive :provision_box
        box.should_receive :push_box_updated_message

        expect {
          box.enqueue_provision!
        }.to change(box, :state).from('born').to('provisioning')
      end
    end

    describe '#enqueue_start' do
      ['provisioning', 'stopped'].each do |initial_state|
        context "when the initial state is #{initial_state}" do
          before { box.update_attribute :state, initial_state }

          it 'enqueues a start box job' do
            mock_coach.should_receive :start_box
            box.should_receive :push_box_updated_message

            expect {
              box.enqueue_start!
            }.to change { box.state }.from(initial_state).to('starting')
          end
        end
      end
    end

    describe '#start' do
      before do
        box.update_attribute :state, 'starting'
      end

      it 'starts the box' do
        box.should_receive :push_box_updated_message
        expect {
          box.start!
        }.to change { box.state }.from('starting').to('running')
      end
    end

    describe '#enqueue_stop' do
      before { box.update_attribute :state, 'running' }

      it 'enqueues a stop box job' do
        mock_coach.should_receive :stop_box
        box.should_receive :push_box_updated_message

        expect {
          box.enqueue_stop!
        }.to change { box.state }.from('running').to('stopping')
      end
    end

    describe '#stop' do
      before { box.update_attribute :state, 'stopping' }

      it 'stops the box' do
        box.should_receive :push_box_updated_message
        expect {
          box.stop!
        }.to change { box.state }.from('stopping').to('stopped')
      end
    end

    describe '#enqueue_restart' do
      before { box.update_attribute :state, 'running' }

      it 'enqueues a restart box job' do
        mock_coach.should_receive :restart_box
        box.should_receive :push_box_updated_message

        expect {
          box.enqueue_restart!
        }.to change { box.state }.from('running').to('restarting')
      end
    end

    describe '#restart' do
      before { box.update_attribute :state, 'restarting' }

      it 'restarts the box' do
        box.should_receive :push_box_updated_message
        expect {
          box.restart!
        }.to change { box.state }.from('restarting').to('running')
      end
    end

    describe '#enqueue_terminate' do
      before { box.update_attribute :state, 'stopped' }

      it 'enqueues a terminate box job' do
        mock_coach.should_receive :terminate_box
        box.should_receive :push_box_updated_message

        expect {
          box.enqueue_terminate!
        }.to change { box.state }.from('stopped').to('terminating')
      end
    end

    describe '#terminate' do
      before do
        box.stub :push_box_updated_message
        box.update_attribute :state, 'terminating'
      end

      it 'terminates the box' do
        box.should_receive :push_box_updated_message
        expect {
          box.terminate!
        }.to change { box.state }.from('terminating').to('terminated')
      end

      it 'updates the termination time of the box' do
        Timecop.freeze 5.hours.from_now do
          expect {
            box.terminate!
          }.to change { box.terminated_at.to_i }.to(Time.now.to_i)
        end
      end

      it 'deallocates any associated n2o allocation' do
        box.should_receive :deallocate_n2o!
        box.terminate!
      end
    end

    describe '#enqueue_reconfigure' do
      before { box.update_attribute :state, 'running' }

      it 'enqueues a change specs box job' do
        mock_coach.should_receive(:reconfigure).with(memory: 512, disk_space: 1000)
        box.should_receive :push_box_updated_message

        expect {
          box.storage = 1000
          box.memory = 512

          box.enqueue_reconfigure!
        }.to change { box.state }.from('running').to('reconfiguring')
      end
    end

    describe '#reconfigure' do
      before { box.update_attribute :state, 'reconfiguring' }

      it 'changes the box specs' do
        box.should_receive :push_box_updated_message
        expect {
          box.reconfigure!
        }.to change { box.state }.from('reconfiguring').to('running')
      end
    end
  end

  describe '#push_box_updated_message' do
    let(:user1) { create :user }
    let(:user2) { create :user }
    let(:user3) { create :user }
    let!(:box) { create :box, owner: user1, users: [user1, user3] }

    it 'pushes aio:box_updated notification' do
      channel = double('channel')
      [user1, user3].each do |user|
        Pusher.should_receive(:[]).with("private-user-#{user.id}") { channel }
        channel.should_receive(:trigger).ordered.with('aio:box_updated', box.serialize_as_hash)
      end
      box.push_box_updated_message
    end
  end

  describe '#backend_available?' do
    let!(:region) { create :region, enabled: true }
    let!(:box) { create :box, region: region }

    it 'return false when box is under maintenance' do
      box.update_attribute :state, "migrating"
      expect(box.backend_available?).to be_false
    end

    context 'when region is down' do
      before { region.update_attribute('state', 'down') }

      it 'returns false' do
        expect(box.backend_available?).to be_false
      end
    end

    context 'when region is going down' do
      before { region.update_attribute('state', 'going_down') }

      it 'returns true' do
        expect(box.backend_available?).to be_true
      end
    end

    context 'when region is box creation disabled' do
      before { region.update_attribute('state', 'box_creation_disabled') }

      it 'returns true' do
        expect(box.backend_available?).to be_true
      end
    end

    context 'when region is up' do
      before { region.update_attribute('state', 'up') }

      it 'returns true' do
        expect(box.backend_available?).to be_true
      end
    end

    context 'when region is disabled' do
      before { region.update_attribute('enabled', false) }

      it 'returns false' do
        expect(box.backend_available?).to be_false
      end
    end
  end

  describe '#{add,remove}_public_key' do
    let!(:box) { create :box }
    let!(:mock_coach) { double('coach') }
    let!(:dummy_key) { 'ssh-rsa S0m3DummYk3Y key@example.com' }

    before { box.stub!(:coach) { mock_coach } }

    describe '#add_public_key' do
      it "adds a public key to the box's authorized_keys file" do
        mock_coach.should_receive(:add_public_key).with(dummy_key)
        box.add_public_key(dummy_key)
      end
    end

    describe '#remove_public_key' do
      it "removes a public key from the box's authorized_keys file" do
        mock_coach.should_receive(:remove_public_key).with(dummy_key)
        box.remove_public_key(dummy_key)
      end
    end
  end

  describe "#generate_key_pair" do
    let!(:box) { create :box }
    let!(:mock_boxer) { double('boxer') }
    let!(:mock_key)   { double('ssh_key', private_key: 'some-private-key', ssh_public_key: 'some-public-key') }

    before { box.stub!(:boxer) { mock_boxer } }

    it "adds a public key to the box's authorized_keys file" do
      GenerateSSHKey.should_receive(:generate) { mock_key }

      expect {
        @key_pair = box.generate_key_pair
      }.to change(box.key_pairs, :count).by(1)

      @key_pair.private_key.should == 'some-private-key'
      @key_pair.public_key.should == 'some-public-key'
    end
  end

  describe '#container_name' do
    it 'includes box id and name' do
      box = Box.new(name: "hello")
      box.id = 1
      box.container_name.should eq("hello-1")
    end
  end

  describe '#collaborators' do
    let(:user) { create :user }
    let(:collaborator) { create :user }
    let(:collaborator2) { create :user }
    let(:collaborator3) { create :user }
    let(:box) { create :box, owner: user, users: [user, collaborator, collaborator2] }

    it "returns the box's users except the owner" do
      expect(box.collaborators).to eq [collaborator, collaborator2]
    end
  end

  describe '#collaborator_status' do
    let!(:user_1)    { create :user, email: 'i@mclov.in' }
    let!(:user_2)    { create :user, email: 'j@mclov.in' }
    let!(:box)       { create :box, owner: user_1, users: [user_1] }

    it 'returns Box::COLLABORATOR_EXISTS when a collaborator already exists' do
      box.collaborator_status(user_1.username).should eq Box::COLLABORATOR_EXISTS
    end

    it 'returns Box::ADD_COLLABORATOR when its a user who exists but has not been added as a collaborator' do
      box.collaborator_status(user_2.email).should eq Box::ADD_COLLABORATOR
    end

    it 'returns Box::INVITE_COLLABORATOR when its a user who exists but has not been added as a collaborator' do
      box.collaborator_status('k@mclov.in').should eq Box::INVITE_COLLABORATOR
    end
  end

  describe '#add_collaborator' do
    let!(:user)           { create :user }
    let!(:collaborator)   { create :user }
    let!(:collaborator2)  { create :user }
    let!(:box) { create :box, owner: user, users: [user, collaborator] }

    context 'when the user has not been added as a collaborator' do
      it 'adds the user' do
        expect {
          res = box.add_collaborator collaborator2.email
          res.should be_persisted
          res.should eq(collaborator2)
        }.to change { box.collaborators.count }.by 1
      end
    end

    context 'when the user is already added' do
      before { box.users << collaborator2 }

      it 'does not add the user' do
        expect {
          box.add_collaborator collaborator2.email
        }.to_not change { box.collaborators.count }
      end
    end

    context 'when the user does not exist' do
      it 'does not add the user' do
        expect {
          box.add_collaborator 'x@abc.com'
        }.to_not change { box.collaborators.count }
      end
    end
  end

  describe '#invite_collaborator' do
    let!(:user) { create :user }
    let!(:box)  { create :box, owner: user }

    it 'creates a collaboration invite for the box, from the owner with identifier as email' do
      collaboration_invite = nil

      expect {
        collaboration_invite = box.invite_collaborator "back.to@thefuture.com"
      }.to change { CollaborationInvite.count }.by 1

      collaboration_invite.email.should eq("back.to@thefuture.com")
      collaboration_invite.should be_activated
      collaboration_invite.box.should eq(box)
    end
  end

  describe '#round_down_memory_and_storage' do
    before do
      create :key_value, key: Box::N2O_MIN_MEMORY_MB,  value: 384
      create :key_value, key: Box::N2O_MAX_MEMORY_MB,  value: 2048
      create :key_value, key: Box::N2O_MIN_STORAGE_MB,  value: 750
      create :key_value, key: Box::N2O_MAX_STORAGE_MB,  value: 10000
    end

    it 'rounds down memory to closest multiple of 128mb and ensures it is at least 384mb' do
      box = build :box, memory: 600
      box.round_down_memory_and_storage
      expect(box.memory).to eq 512

      box.memory = 383
      box.round_down_memory_and_storage
      expect(box.memory).to eq 384

      box.memory = 385
      box.round_down_memory_and_storage
      expect(box.memory).to eq 384

      box.memory = 1000
      box.round_down_memory_and_storage
      expect(box.memory).to eq 896

      box.memory = 1024
      box.round_down_memory_and_storage
      expect(box.memory).to eq 1024
    end

    it 'rounds down storage to closest multiple of 250mb and ensures it is at least 750mb' do
      box = build :box, storage: 800
      box.round_down_memory_and_storage
      expect(box.storage).to eq 750

      box.storage = 749
      box.round_down_memory_and_storage
      expect(box.storage).to eq 750

      box.storage = 751
      box.round_down_memory_and_storage
      expect(box.storage).to eq 750

      box.storage = 1000
      box.round_down_memory_and_storage
      expect(box.storage).to eq 1000

      box.storage = 999
      box.round_down_memory_and_storage
      expect(box.storage).to eq 750
    end
  end

  describe '#n2o_cost' do
    let!(:box) { create :box, memory: 384, storage: 750 }

    before do
      create 'key_value', key: N2oAllocation::N2O_128MB_MEMORY,  value: 40
      create 'key_value', key: N2oAllocation::N2O_250MB_STORAGE, value: 10
    end

    it 'calculates the n2o needed to provision a box with given memory and storage' do
      expect(box.n2o_cost).to eq 150

      box.memory = 512
      box.storage = 2000
      expect(box.n2o_cost).to eq 240
    end
  end

  describe '#n2o_allocation_needed?' do
    let!(:user)     { create :user }
    let!(:n2o_fill) { create :n2o_fill, amount: 1000, kind: N2oFill::Kind::FAVOR, user: user }
    let!(:box)      { build :box, owner: user, memory: 512, storage: 5000 }

    before do
      create 'key_value', key: N2oAllocation::N2O_128MB_MEMORY,  value: 40
      create 'key_value', key: N2oAllocation::N2O_250MB_STORAGE, value: 10
    end

    context 'when record is new (create)' do
      it 'returns true' do
        expect(box.n2o_allocation_needed?).to be_true
      end
    end

    context 'when record is persisted (update)' do
      before { box.save! }

      context 'when nothing is changed' do
        it 'returns false' do
          expect(box.n2o_allocation_needed?).to be_false
        end
      end

      context 'when memory is changed' do
        before { box.memory = 1024 }

        it 'returns true' do
          expect(box.n2o_allocation_needed?).to be_true
        end
      end

      context 'when storage is changed' do
        before { box.storage = 10000 }

        it 'returns true' do
          expect(box.n2o_allocation_needed?).to be_true
        end
      end

      context 'when other fields are changed' do
        before { box.state = 'stopping' }

        it 'returns false' do
          expect(box.n2o_allocation_needed?).to be_false
        end
      end
    end
  end

  describe '#configuration_changed?' do
    let!(:box)   { build :box }

    context 'when memory is changed' do
      before { box.memory = 1024 }

      it 'returns true' do
        expect(box.configuration_changed?).to be_true
      end
    end

    context 'when storage is changed' do
      before { box.storage = 10000 }

      it 'returns true' do
        expect(box.configuration_changed?).to be_true
      end
    end

    context 'when other fields are changed' do
      before { box.state = 'stopping' }

      it 'returns false' do
        expect(box.configuration_changed?).to be_false
      end
    end
  end

  describe '#n2o_delta' do
    let!(:user)     { create :user }
    let!(:n2o_fill) { create :n2o_fill, amount: 1000, kind: N2oFill::Kind::FAVOR, user: user }
    let!(:box)      { build  :box, owner: user, memory: 384, storage: 750 }

    before do
      create 'key_value', key: N2oAllocation::N2O_128MB_MEMORY,  value: 40
      create 'key_value', key: N2oAllocation::N2O_250MB_STORAGE, value: 10
    end

    context 'when box is not saved' do
      it 'is greater than zero' do
        expect(box.n2o_delta).to eql 0
      end
    end

    context 'when box is saved' do
      before { box.save! }

      context 'when memory is changed to a larger value' do
        before { box.memory = 1024 }

        it 'is greater than zero' do
          expect(box.n2o_delta).to be > 0
        end
      end

      context 'when storage is changed to a larger value' do
        before { box.storage = 10000 }

        it 'is greater than zero' do
          expect(box.n2o_delta).to be > 0
        end
      end

      context 'when memory and storage are both changed but the n2o cost is less than zero' do
        before do
          box.memory = 64
          box.storage = 1000
        end

        it 'is less than zero' do
          expect(box.n2o_delta).to be < 0
        end
      end

      context 'when memory and storage are both changed but the n2o cost is zero' do
        before do
          box.memory = 256
          box.storage = 1750
        end

        it 'is zero' do
          expect(box.n2o_delta).to eql 0
        end
      end
    end
  end

  describe '#validate_free_n2o' do
    let!(:user) { create :user }
    let(:box)   { build :box, owner: user, memory: 384, storage: 750 }

    before do
      create :key_value, key: N2oAllocation::N2O_128MB_MEMORY,  value: 40
      create :key_value, key: N2oAllocation::N2O_250MB_STORAGE, value: 10
    end

    context 'when user does not have sufficient n2o to create the box' do
      let!(:fill) { create :n2o_fill, user: user, amount: 149 }

      it 'fails validation' do
        box.send :validate_free_n2o
        expect(box.errors[:base]).to include 'Not enough N2O'
      end
    end

    context 'when user has sufficient n2o to create the box' do
      let!(:fill) { create :n2o_fill, user: user, amount: 150 }

      it 'passes validation' do
        box.send :validate_free_n2o
        expect(box.errors[:base]).not_to include 'Not enough N2O'
      end
    end

    context 'when box already has n2o allocations' do
      let!(:fill) { create :n2o_fill, user: user, amount: 160 }
      before      { box.save! }

      context 'when there enough n2o to upgrade' do
        before { box.storage = 1000 }

        it 'temporarily deallocates n2o in a traction, validates and passes, then restores n2o allocations' do
          expect(user.free_n2o).to eq 10
          box.send :validate_free_n2o
          expect(box.errors[:base]).not_to include 'Not enough N2O'
          expect(user.free_n2o).to eq 10
        end
      end

      context 'when there is not enough to upgrade' do
        before { box.storage = 1250 }

        it 'temporarily deallocates n2o in a traction, validates and fails, then restores n2o allocations' do
          expect(user.free_n2o).to eq 10
          box.send :validate_free_n2o
          expect(box.errors[:base]).to include 'Not enough N2O'
          expect(user.free_n2o).to eq 10
        end
      end
    end
  end

  describe '#allocate_n2o!' do
    let!(:box) { create :box }

    context 'when n2o cost for box is 0' do
      before do
        box.owner.stub(:free_n2o).and_return 0
        box.stub(:n2o_cost).and_return 0
      end

      it 'does not create an N2oAllocation object' do
        expect(box.n2o_allocations).to be_empty
        box.send :allocate_n2o!
        expect(box.n2o_allocations.reload).to be_empty
      end
    end

    context 'when n2o cost for box is greater than 0' do
      before do
        box.owner.stub(:free_n2o).and_return 300
        box.stub(:n2o_cost).and_return 300
      end

      it 'creates an N2oAllocation object with the cost of the box' do
        expect(box.n2o_allocations).to be_empty
        box.send :allocate_n2o!
        n2o_alloc = box.n2o_allocations.reload.first

        expect(n2o_alloc).to be_present
        expect(n2o_alloc.user).to eq box.owner
        expect(n2o_alloc.kind).to eq N2oAllocation::Kind::BOX_CREATION
        expect(n2o_alloc.resource).to eq box
        expect(n2o_alloc.amount).to eq 300
        expect(n2o_alloc).not_to be_deallocated
      end

      context 'when there is a preexisting n2o allocation' do
        before { box.send :allocate_n2o! }

        it 'deallocates the preexisting allocation and creates a new alocation' do
          prev_n2o_alloc = box.n2o_allocations.reload.first
          expect(prev_n2o_alloc).not_to be_deallocated

          box.send :allocate_n2o!
          new_n2o_alloc = box.n2o_allocations.reload.last
          expect(prev_n2o_alloc.reload).to be_deallocated
          expect(new_n2o_alloc).not_to eq prev_n2o_alloc
        end
      end
    end
  end

  describe '#deallocate_n2o!' do
    let(:user) { create :user }
    let!(:box) { create :box, owner: user }

    before do
      create :n2o_fill, user: user, amount: 500
      create :n2o_allocation, user: user, resource: box, amount: 300
      create :n2o_allocation, user: user, resource: box, amount: 100
      create :n2o_allocation, user: user, resource: box, amount: 30, deallocated_at: Time.now
      create :n2o_allocation, user: user, amount: 50
      box.reload
    end

    it 'deallocates any associated n2o allocation' do
      expect(user.used_n2o).to eq 450
      box.send :deallocate_n2o!
      expect(user.reload.used_n2o).to eq 50
    end
  end

  describe ".count_by_region" do
    let!(:region_1) { create :region, name: 'region-1', enabled: true }
    let!(:region_2) { create :region, name: 'region-2', enabled: true }
    let!(:region_3) { create :region, name: 'region-3', enabled: true }

    let!(:box1)     { create :box, region: region_1, state: 'running' }
    let!(:box2)     { create :box, region: region_1, state: 'running' }
    let!(:box3)     { create :box, region: region_1 }

    let!(:box4)     { create :box, region: region_2 }

    let!(:box5)     { create :box, region: region_3, state: 'running' }
    let!(:box6)     { create :box, region: region_3 }

    context "no options" do
      it "should return a hash which has the number of boxes in each region (sorted in desc order)" do
        Box.count_by_region.should == { 'region-1' => 3, 'region-3' => 2, 'region-2' => 1 }
      end
    end

    context "with state set" do
      it "should return a hash which has the number of boxes in each region which are running (sorted in desc order)" do
        Box.count_by_region(state: 'running').should == { 'region-1' => 2, 'region-3' => 1 }
      end
    end
  end

  describe ".count_by_template" do
    let!(:template_1) { create :box_template, name: 'template-1' }
    let!(:template_2) { create :box_template, name: 'template-2' }
    let!(:template_3) { create :box_template, name: 'template-3' }

    let!(:box1)     { create :box, box_template: template_1, state: 'running' }
    let!(:box2)     { create :box, box_template: template_1, state: 'running' }
    let!(:box3)     { create :box, box_template: template_1 }

    let!(:box4)     { create :box, box_template: template_2 }

    let!(:box5)     { create :box, box_template: template_3, state: 'running' }
    let!(:box6)     { create :box, box_template: template_3 }

    context 'with no options' do
      it "should return a hash which has the number of boxes in each template(sorted in desc order)" do
        Box.count_by_template.should == { 'template-1' => 3, 'template-3' => 2, 'template-2' => 1 }
      end
    end

    context 'with state set' do
      it "should return a hash which has the number of boxes in each region which are running (sorted in desc order)" do
        Box.count_by_template(state: 'running').should == { 'template-1' => 2, 'template-3' => 1 }
      end
    end
  end

  describe ".count_by_memory" do
    let!(:box1)     { create :box, memory: 1024, state: 'running' }
    let!(:box2)     { create :box, memory: 1024, state: 'running' }
    let!(:box3)     { create :box, memory: 1024 }

    let!(:box4)     { create :box, memory: 512 }

    let!(:box5)     { create :box, memory: 384, state: 'running' }
    let!(:box6)     { create :box, memory: 384 }

    context "with no options" do
      it "should return a hash which has the number of boxes in each memory block (sorted in desc order)" do
        Box.count_by_memory.should == { 1024 => 3, 384 => 2, 512 => 1 }
      end
    end

    context "with state set" do
      it "should return a hash which has the number of boxes in each memory block (sorted in desc order)" do
        Box.count_by_memory(state: 'running').should == { 1024 => 2, 384 => 1 }
      end
    end
  end

  describe ".count_by_storage" do
    let!(:box1)     { create :box, storage: 1000, state: 'running' }
    let!(:box2)     { create :box, storage: 1000, state: 'running' }
    let!(:box3)     { create :box, storage: 1000 }

    let!(:box4)     { create :box, storage: 500 }

    let!(:box5)     { create :box, storage: 250, state: 'running' }
    let!(:box6)     { create :box, storage: 250 }

    context "with no options" do
      it "should return a hash which has the number of boxes in each storage block (sorted in desc order)" do
        Box.count_by_storage.should == { 1000 => 3, 250 => 2, 500 => 1 }
      end
    end

    context "with state set" do
      it "should return a hash which has the number of boxes in each storage block (sorted in desc order)" do
        Box.count_by_storage(state: 'running').should == { 1000 => 2, 250 => 1 }
      end
    end
  end

  describe "counts" do
    let!(:box1)     { create :box, state: 'running' }
    let!(:box2)     { create :box, state: 'running' }
    let!(:box3)     { create :box }

    let!(:box4)     { create :box }

    let!(:box5)     { create :box, state: 'running' }
    let!(:box6)     { create :box, state: 'terminated' }

    describe ".running_count" do
      it "should return the total count of running boxes" do
        expect(Box.running_count).to eql('count' => 3)
      end
    end

    describe ".unterminated_count" do
      it "should return the total count of running boxes" do
        expect(Box.unterminated_count).to eql('count' => 5)
      end
    end

    describe ".total_count" do
      it "should return the total count of all boxes" do
        expect(Box.total_count).to eql('count' => 6)
      end
    end
  end

  describe '#start_migration' do
    let!(:mock_coach) { double('coach').as_null_object }
    let!(:box)        { create :box }
    before do
      box.stub!(:coach) { mock_coach }
      box.stub :push_box_updated_message
    end

    it 'migrate the box from current host' do
      mock_coach.should_receive(:migrate)
      box.start_migration
    end

    it 'marks the box as migrating' do
      expect {
        box.start_migration
      }.to change { box.reload.state }.to("migrating")
    end

    it 'updates state of the box' do
      box.should_receive(:push_box_updated_message)
      box.start_migration
    end
  end

  describe '#finish_migration' do
    let!(:box)        { create :box }

    it 'updates the state and version' do
      box.update_attribute :state, "migrating"
      box.should_receive :push_box_updated_message
      box.finish_migration
      box.reload
      box.state.should eq("stopped")
      box.version.should eq("cersei")
    end
  end
end
