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
  it { should_not allow_mass_assignment_of :cpu_multiplier }
  it { should_not allow_mass_assignment_of :virtual_memory }

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
      expect(box.version).to eq("v666")
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
    it { should validate_presence_of(:cpu_multiplier) }

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

    describe 'availability of a name' do
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

    describe '#virtual_memory' do
      let!(:user) { create :user }

      context 'for a new unsaved box' do
        let(:box) { build :box, owner: user, memory: 512 }

        it 'should be nil if not set' do
          expect(box.virtual_memory).to be_nil
        end
      end

      context 'for a saved box' do
        context 'when virtual_memory is not set' do
          let(:box) { create :box, owner: user, memory: 512 }

          it 'should be half the value as memory' do
            expect(box.virtual_memory).to eq(256)
          end
        end

        context 'when virtual_memory is set' do
          let(:box) { create :box, owner: user, memory: 512, virtual_memory: 1024 }

          it 'should be set correctly' do
            expect(box.virtual_memory).to eq(1024)
          end
        end
      end
    end

    describe 'n2o check' do
      let(:box) { create :box }

      context 'when n2o_allocation_needed? is true' do
        before { box.stub(:n2o_allocation_needed?).and_return true }

        it 'checks whether there is sufficient free n2o' do
          expect(box).to receive :validate_free_n2o
          box.valid?
        end
      end

      context 'when n2o_allocation_needed? is false' do
        before { box.stub(:n2o_allocation_needed?).and_return false }

        it 'does not check whether there is sufficient free n2o' do
          expect(box).not_to receive :validate_free_n2o
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
          expect(new_box.error_on(:region_id).size).to eq(1)
        end
      end

      context 'when owner is an admin' do
        let!(:admin_user) { create :admin }

        it 'do not add any errors on region' do
          new_box = build :box, owner: admin_user, region: unavailable_region
          new_box.valid?

          expect(new_box.errors_on(:region_id).size).to eq(0)
        end
      end

      it 'does not affect saving exisiting boxes' do
        box.region = unavailable_region
        expect(box).to be_valid
      end
    end
  end

  describe 'scopes' do
    context 'with boxes in various states' do
      let!(:box_1) { create :box                        }
      let!(:box_2) { create :box, state: 'terminated'   }
      let!(:box_3) { create :box, state: 'running'      }
      let!(:box_4) { create :box, state: 'starting'     }
      let!(:box_5) { create :box, state: 'stopping'     }
      let!(:box_6) { create :box, state: 'provisioning' }

      describe '.unterminated' do
        it "should return all boxes which don't have the state set to 'terminated'" do
          expect(Box.unterminated.to_a).to match_array([box_1, box_3, box_4, box_5, box_6])
        end
      end

      describe '.running' do
        it "should return all boxes which don't have the state set to 'terminated'" do
          expect(Box.running.to_a).to eq([box_3])
        end
      end

      describe '.dangling' do
        it "should return all boxes which are either born, provisioning, starting, stopping" do
          expect(Box.dangling.to_a).to match_array([box_1, box_4, box_5, box_6])
        end
      end
    end

    context 'with boxes and subscriptions in various states' do
      let!(:user) { create :user }
      let!(:user_with_active_subscription) { create :user }
      let!(:user_with_pending_subscription) { create :user }
      let!(:user_with_canceled_subscription) { create :user }
      let!(:user_with_payment_due_subscription) { create :user } # should we shutdown the boxes of users whose payments are due?

      let!(:active_subscription) { create :subscription, state: 'active', user: user_with_active_subscription }
      let!(:pending_subscription) { create :subscription, state: 'pending', user: user_with_pending_subscription }
      let!(:canceled_subscription) { create :subscription, state: 'canceled', user: user_with_canceled_subscription }
      let!(:payment_due_subscription) { create :subscription, state: 'active', user: user_with_payment_due_subscription, payment_due: true }

      let(:free_box_1) { create :box, name: 'free-box-1', owner: user, state: 'running', touched_at: 3.hours.ago - 1.second}
      let(:free_box_2) { create :box, name: 'free-box-2', owner: user, state: 'running', touched_at: 3.hours.ago }
      let(:free_box_3) { create :box, name: 'free-box-3', owner: user, state: 'running', touched_at: nil }
      let(:paid_box_1) { create :box, name: 'paid-box-1', owner: user_with_active_subscription, state: 'running', touched_at: 3.hours.ago - 1.second }
      let(:pending_box_1) { create :box, name: 'pending-box-1', owner: user_with_pending_subscription, state: 'running', touched_at: 3.hours.ago - 1.second }
      let(:canceled_box_1) { create :box, name: 'canceled-box-1', owner: user_with_canceled_subscription, state: 'running', touched_at: 3.hours.ago - 1.second }
      let(:payment_due_box_1) { create :box, name: 'payment-due-box-1', owner: user_with_payment_due_subscription, state: 'running', touched_at: 3.hours.ago - 1.second }
      let(:stopped_box_1) { create :box, name: 'stopped-box-1', owner: user, state: 'stopped', touched_at: 3.hours.ago - 1.second}

      before do
        Timecop.freeze
        free_box_1; free_box_2; free_box_3; paid_box_1; pending_box_1; canceled_box_1; payment_due_box_1; stopped_box_1
      end

      after { Timecop.return }

      describe '.unpaid' do
        it 'returns all boxes of free users (including users who have a payment due on their pending or canceled subscription)' do
          expect(Box.unpaid).to match_array [free_box_1, free_box_2, free_box_3, pending_box_1, canceled_box_1, payment_due_box_1, stopped_box_1]
        end
      end

      describe '.free_idle' do
        before do
          Settings.stub(:idle_box_grace_period).and_return 3.hours.to_i
        end

        it "returns all running boxes of free users that haven't been touched for a period specified in the env var" do
          expect(Box.free_idle).to match_array [free_box_1, free_box_3, pending_box_1, canceled_box_1, payment_due_box_1]
        end
      end

      describe '.untouched_since' do
        let(:untouched_box_1) { create :box, name: 'untouched-1', owner: user, touched_at: 3.days.ago - 1.second }
        let(:untouched_box_2) { create :box, name: 'untouched-2', owner: user, touched_at: nil, created_at: 3.days.ago - 1.second }
        let(:touched_box_1) { create :box, name: 'touched-1', owner: user, touched_at: 3.days.ago }
        let(:touched_box_2) { create :box, name: 'touched-2', owner: user, touched_at: nil, created_at: 3.days.ago }

        before do
          Timecop.freeze
          untouched_box_1; untouched_box_2;
          touched_box_1; touched_box_2
        end

        after { Timecop.return }

        it "returns all boxes that haven't been touched since the given time" do
          expect(Box.untouched_since(3.days.ago)).to match_array [untouched_box_1, untouched_box_2]
        end
      end

      describe '.due_for_termination_notice' do
        let(:stopped_box_2) { create :box, name: 'stopped-box-2', owner: user, state: 'stopped', touched_at: 90.days.ago - 1.second }
        let(:stopped_box_3) { create :box, name: 'stopped-box-3', owner: user, state: 'stopped', touched_at: nil }
        let(:stopped_box_4) { create :box, name: 'stopped-box-5', owner: user_with_active_subscription, state: 'stopped', touched_at: 90.days.ago - 1.second }
        let(:stopped_box_5) { create :box, name: 'stopped-box-4', owner: user_with_pending_subscription, state: 'stopped', touched_at: 90.days.ago - 1.second }
        let(:stopped_box_6) { create :box, name: 'stopped-box-6', owner: user_with_canceled_subscription, state: 'stopped', touched_at: 90.days.ago - 1.second }
        let(:stopped_box_7) { create :box, name: 'stopped-box-7', owner: user_with_payment_due_subscription, state: 'stopped', touched_at: 90.days.ago - 1.second }
        let(:stopped_box_8) { create :box, name: 'stopped-box-8', owner: user, state: 'stopped', touched_at: 90.days.ago - 1.second, termination_notice_sent_at: 1.week.ago }
        let(:stopped_box_9) { create :box, name: 'stopped-box-9', owner: user, state: 'stopped', touched_at: nil, created_at: 90.days.ago}
        let(:stopped_box_10) { create :box, name: 'stopped-box-10', owner: user, state: 'stopped', touched_at: nil, created_at: 90.days.ago - 1.second}

        before do
          Timecop.freeze
          stopped_box_2; stopped_box_3; stopped_box_4;
          stopped_box_5; stopped_box_6;stopped_box_7;
          stopped_box_8; stopped_box_9; stopped_box_10
          Settings.stub(:box_termination_grace_period_in_days).and_return '90'
        end

        after { Timecop.return }

        it "returns all stopped boxes that haven't been touched for a period specified in the env var" do
          expect(Box.due_for_termination_notice).to match_array [stopped_box_2, stopped_box_5, stopped_box_6, stopped_box_7, stopped_box_10]
        end
      end

      describe '.eligible_for_termination' do
        let(:eligible_1) { create :box, name: 'eligible-box-1', owner: user, state: 'stopped', touched_at: 90.days.ago - 1.second, termination_notice_sent_at: 5.days.ago - 1.second }
        let(:eligible_2) { create :box, name: 'eligible-box-2', owner: user, state: 'stopped', touched_at: nil, created_at: 90.days.ago - 1.second, termination_notice_sent_at: 5.days.ago - 1.second }
        let(:ineligible_1) { create :box, name: 'ineligible-box-1', owner: user, state: 'running', touched_at: 90.days.ago - 1.second, termination_notice_sent_at: 5.days.ago - 1.second }
        let(:ineligible_2) { create :box, name: 'ineligible-box-2', owner: user, state: 'stopped', touched_at: 90.days.ago - 1.second, termination_notice_sent_at: nil }
        let(:ineligible_3) { create :box, name: 'ineligible-box-3', owner: user, state: 'stopped', touched_at: 90.days.ago - 1.second, termination_notice_sent_at: 5.days.ago }
        let(:ineligible_4) { create :box, name: 'ineligible-box-4', owner: user, state: 'stopped', touched_at: 5.days.ago, termination_notice_sent_at: 5.days.ago }
        let(:ineligible_5) { create :box, name: 'ineligible-box-5', owner: user, state: 'stopped', touched_at: nil, termination_notice_sent_at: 5.days.ago, created_at: 90.days.ago - 1.second }
        let(:ineligible_6) { create :box, name: 'ineligible-box-6', owner: user, state: 'stopped', touched_at: 90.days.ago, termination_notice_sent_at: 5.days.ago - 1.second }

        before do
          Timecop.freeze
          eligible_1; eligible_2;
          ineligible_1; ineligible_2; ineligible_3; ineligible_4; ineligible_5; ineligible_6
          Settings.stub(:box_termination_grace_period_in_days).and_return '90'
        end

        after { Timecop.return }

        it "returns all stopped boxes that have been sent a termination notice > 5 days ago and haven't been touched for a period specified in the env var" do
          expect(Box.eligible_for_termination).to match_array [eligible_1, eligible_2]
        end
      end
    end
  end

  describe 'delegates' do
    let!(:region_1) { create :region, box_server_uri: 'https://boxserver.example.com:1234', enabled: true }
    let!(:box_1)    { create :box, region: region_1 }

    describe "box_server_uri" do
      it "should return the box server uri of the region that it belongs to" do
        expect(box_1.box_server_uri).to eq('https://boxserver.example.com:1234')
      end
    end
  end

  context 'before validation' do
    let!(:box) { build :box, name: 'Fragrant-Wind-69' }

    it 'downcases name' do
      box.valid?
      expect(box.name).to eq('fragrant-wind-69')
    end

    it 'rounds down memory and storage' do
      expect(box).to receive :round_down_memory_and_storage
      box.valid?
    end
  end

  context 'before save' do
    let!(:user) { create :user }
    it 'sets virtual_memory to be the half the memory if virtual_memory is not set' do
      box = create :box, owner: user, memory: 1024
      box.virtual_memory = nil
      box.save
      expect(box.virtual_memory).to eq(512)
    end

    it "doesn't change virtual_memory if it's already set" do
      box = create :box, owner: user, memory: 1024
      box.virtual_memory = 2048
      box.save
      expect(box.virtual_memory).to eq(2048)
    end
  end

  context 'before create' do
    it 'adds owner to users' do
      user = create :user
      box = create :box, owner: user
      expect(box.users).to eq([user])
    end
  end

  context 'after save' do
    let!(:box) { create :box }

    context 'when n2o_delta is positive' do
      before do
        box.stub(:n2o_delta).and_return 200
      end

      it 'invokes allocate_n2o! after saving' do
        expect(box).to receive :allocate_n2o!
        box.save
      end
    end

    context 'when n2o_delta is negative' do
      before { box.stub(:n2o_delta).and_return(-200) }

      it 'invokes allocate_n2o! after saving' do
        expect(box).to receive :allocate_n2o!
        box.save
      end
    end

    context 'when n2o_delta is zero' do
      before { box.stub(:n2o_delta).and_return(0) }

      it 'does not invoke allocate_n2o! after saving' do
        expect(box).not_to receive :allocate_n2o!
        box.save
      end
    end
  end

  describe '#coach' do
    it 'memoizes and returns a new Coach instance' do
      mock_coach = instance_double('Coach')
      allow_any_instance_of(Box).to receive(:enqueue_provision!)

      box = create :box

      Coach.stub(:new) do |_box|
        expect(_box).to eq(box)
        mock_coach
      end

      coach = box.coach
      expect(coach).to eq(mock_coach)
      expect(box.instance_variable_get(:@coach)).to eq(mock_coach)
    end
  end

  describe 'state machine' do
    let(:box_template)  { create :box_template, image: 'rails' }
    let!(:mock_coach)   { instance_double('Coach') }
    let!(:box)          { create :box }

    before { box.stub(:coach) { mock_coach } }

    context 'wrapper events' do
      it 'saves box state even when it fails to push box updated message' do
        box.update_attribute :state, 'provisioning'
        expect(box).to receive(:push_box_updated_message).and_raise
        expect {
          box.orphan!
        }.to raise_error
        expect(box.state).to eql('failed')
      end

      it 'returns the result of the underlying event' do
        allow(box).to receive(:push_box_updated_message)
        box.update_attribute :state, 'provisioning'
        expect(box).to receive(:do_enqueue_provision).and_return(true)

        expect(box.enqueue_provision).to eql true
      end
    end

    describe '#orphan' do
      before { box.update_attribute :state, 'provisioning' }

      it 'changes the state to failed' do
        expect(box).to receive :push_box_updated_message

        expect {
          box.orphan!
        }.to change(box, :state).from('provisioning').to('failed')
      end

      it 'sends an email to notify of the failure' do
        expect(box).to receive :push_box_updated_message

        expect {
          box.orphan!
        }.to change(Delayed::Job, :count).by(1)

        expect(Delayed::Job.first.handler).to match(/'Notifier'\nmethod_name: :box_provisioning_failed\nargs:\n- #{box.id}\n/)
      end
    end

    describe '#enqueue_provision' do
      before { allow(box).to receive :push_box_updated_message }

      it 'creates a key pair for the box' do
        allow(mock_coach).to receive :provision_box

        expect(box).to receive(:generate_key_pair)
        box.enqueue_provision!
      end

      it 'calls the Coach API to provision a box' do
        allow(box).to receive(:generate_key_pair)

        expect(mock_coach).to receive :provision_box
        expect {
          box.enqueue_provision!
        }.to change(box, :state).from('born').to('provisioning')
      end
    end

    describe '#enqueue_start' do
      ['provisioning', 'stopped'].each do |initial_state|
        context "when the initial state is #{initial_state}" do
          before { box.update_attribute :state, initial_state }

          it 'enqueues a start box job with the expected box specs' do
            expect(mock_coach).to receive(:start_box).with(memory: 512, disk_space: 1000, virtual_memory: 1024, cpu_shares: 2 * Box::BASE_CPU_SHARES)
            expect(box).to receive :push_box_updated_message

            expect {
              box.storage = 1000
              box.memory = 512
              box.virtual_memory = 512
              box.cpu_multiplier = 1
              box.stub(:expected_virtual_memory) { 1024 }
              box.stub(:expected_cpu_multiplier) { 2 }

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
        expect(box).to receive :push_box_updated_message
        expect {
          box.start!
        }.to change { box.state }.from('starting').to('running')
      end

      context 'when box was force shutdown' do
        before do
          box.update_attribute :force_shutdown_at, Time.now
          box.stub :push_box_updated_message
        end

        it 'clears the time at which the box was force shutdown' do
          expect {
            box.start!
          }.to change { box.force_shutdown_at }.to(nil)
        end
      end

      context 'when box was not force shutdown' do
        before do
          box.update_attribute :force_shutdown_at, nil
          box.stub :push_box_updated_message
        end

        it 'does not try to clear the time at which the box was force shutdown' do
          expect {
            box.start!
          }.not_to change { box.force_shutdown_at }
        end
      end
    end

    describe '#enqueue_stop' do
      before { box.update_attribute :state, 'running' }

      it 'enqueues a stop box job' do
        expect(mock_coach).to receive :stop_box
        expect(box).to receive :push_box_updated_message

        expect {
          box.enqueue_stop!
        }.to change { box.state }.from('running').to('stopping')
      end
    end

    describe '#stop' do
      before { box.update_attribute :state, 'stopping' }

      it 'stops the box' do
        expect(box).to receive :push_box_updated_message
        expect {
          box.stop!
        }.to change { box.state }.from('stopping').to('stopped')
      end
    end

    describe '#enqueue_restart' do
      before { box.update_attribute :state, 'running' }

      it 'enqueues a restart box job' do
        expect(mock_coach).to receive(:restart_box).with(memory: 512, disk_space: 1000, virtual_memory: 1024, cpu_shares: 2 * Box::BASE_CPU_SHARES)
        expect(box).to receive :push_box_updated_message

        expect {
          box.storage = 1000
          box.memory = 512
          box.virtual_memory = 512
          box.cpu_multiplier = 1
          box.stub(:expected_virtual_memory) { 1024 }
          box.stub(:expected_cpu_multiplier) { 2 }

          box.enqueue_restart!
        }.to change { box.state }.from('running').to('restarting')
      end
    end

    describe '#restart' do
      before { box.update_attribute :state, 'restarting' }

      it 'restarts the box' do
        expect(box).to receive :push_box_updated_message
        expect {
          box.restart!
        }.to change { box.state }.from('restarting').to('running')
      end
    end

    describe '#enqueue_terminate' do
      before { box.update_attribute :state, 'stopped' }

      it 'enqueues a terminate box job' do
        expect(mock_coach).to receive :terminate_box
        expect(box).to receive :push_box_updated_message

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
        expect(box).to receive :push_box_updated_message
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
        expect(box).to receive :deallocate_n2o!
        box.terminate!
      end

      context "when the owner has invalid details" do
        before do
          create :n2o_allocation, resource_id: box.id, resource_type: "Box", user: box.owner
          box.owner.update_attribute :username, "ha ha ha"
        end

        it "terminates successfully" do
          expect {
            box.terminate!
          }.to change { box.state }.to('terminated')
        end
      end
    end

    describe '#enqueue_reconfigure' do
      before { box.update_attribute :state, 'running' }

      it 'enqueues a reconfigure box job with the expected box specs' do
        expect(mock_coach).to receive(:reconfigure).with(memory: 512, disk_space: 1000, virtual_memory: 1024, cpu_shares: 2 * Box::BASE_CPU_SHARES)
        expect(box).to receive :push_box_updated_message

        expect {
          box.storage = 1000
          box.memory = 512
          box.virtual_memory = 512
          box.cpu_multiplier = 1
          box.stub(:expected_virtual_memory) { 1024 }
          box.stub(:expected_cpu_multiplier) { 2 }

          box.enqueue_reconfigure!
        }.to change { box.state }.from('running').to('reconfiguring')
      end
    end

    describe '#reconfigure' do
      before { box.update_attribute :state, 'reconfiguring' }

      it 'changes the box specs' do
        expect(box).to receive :push_box_updated_message
        expect {
          box.reconfigure!
        }.to change { box.state }.from('reconfiguring').to('running')
      end
    end
  end

  describe '#create' do
    let(:owner) { create :user }
    let(:box) { build :box, owner: owner, storage: 1000 }

    before do
      owner.fill_n2o! 500, N2oFill::Kind::FAVOR
      [
        { key: N2oAllocation::N2O_250MB_STORAGE, value: 10 },
        { key: N2oAllocation::N2O_128MB_MEMORY,  value: 40 }
      ].each do |kv|
        unless KeyValue[kv[:key]].present?
          KeyValue.create key: kv[:key], value: kv[:value]
        end
      end
    end

    context "when the owner has invalid details" do
      before { owner.update_attribute :username, "ha ha ha" }

      it 'creates the box' do
        box.save
        expect(box).to be_persisted
      end

      it 'updates the owner balance' do
        expect { box.save }.to change { owner.free_n2o }
      end
    end
  end

  describe '#resize' do
    let(:owner) { create :user }
    let(:box) { create :box, owner: owner, storage: 1000 }

    before do
      owner.fill_n2o! 500, N2oFill::Kind::FAVOR
      [
        { key: N2oAllocation::N2O_250MB_STORAGE, value: 10 },
        { key: N2oAllocation::N2O_128MB_MEMORY,  value: 40 }
      ].each do |kv|
        unless KeyValue[kv[:key]].present?
          KeyValue.create key: kv[:key], value: kv[:value]
        end
      end
    end

    context "when the owner has invalid details" do
      before { owner.update_attribute :username, "ha ha ha" }

      it 'updates owner balance' do
        box.storage = 1250
        expect { box.save }.to change { owner.free_n2o }
      end
    end
  end

  describe '#push_box_updated_message' do
    let(:user1) { create :user }
    let(:user2) { create :user }
    let(:user3) { create :user }
    let!(:box) { create :box, owner: user1, users: [user1, user3] }

    it 'pushes aio:box_updated notification' do
      channel = instance_double('Pusher::Channel')
      [user1, user3].each do |user|
        expect(Shover).to receive(:publish).with(user.id, 'aio:box_updated', box.serialize_as_hash)

        expect(Pusher).to receive(:[]).with("private-user-#{user.id}") { channel }
        expect(channel).to receive(:trigger).ordered.with('aio:box_updated', box.serialize_as_hash)
      end
      box.push_box_updated_message
    end
  end

  describe '#backend_available?' do
    let!(:region) { create :region, enabled: true }
    let!(:box) { create :box, region: region }

    it 'return false when box is under maintenance' do
      box.update_attribute :state, "migrating"
      expect(box.backend_available?).to be_falsey
    end

    context 'when region is down' do
      before { region.update_attribute('state', 'down') }

      it 'returns false' do
        expect(box.backend_available?).to be_falsey
      end
    end

    context 'when region is going down' do
      before { region.update_attribute('state', 'going_down') }

      it 'returns true' do
        expect(box.backend_available?).to be_truthy
      end
    end

    context 'when region is box creation disabled' do
      before { region.update_attribute('state', 'box_creation_disabled') }

      it 'returns true' do
        expect(box.backend_available?).to be_truthy
      end
    end

    context 'when region is up' do
      before { region.update_attribute('state', 'up') }

      it 'returns true' do
        expect(box.backend_available?).to be_truthy
      end
    end

    context 'when region is disabled' do
      before { region.update_attribute('enabled', false) }

      it 'returns false' do
        expect(box.backend_available?).to be_falsey
      end
    end
  end

  describe '#{add,remove}_public_key' do
    let!(:box) { create :box }
    let!(:mock_coach) { instance_double('Coach') }
    let!(:dummy_key) { 'ssh-rsa S0m3DummYk3Y key@example.com' }

    before { box.stub(:coach) { mock_coach } }

    describe '#add_public_key' do
      it "adds a public key to the box's authorized_keys file" do
        expect(mock_coach).to receive(:add_public_key).with(dummy_key)
        box.add_public_key(dummy_key)
      end
    end

    describe '#remove_public_key' do
      it "removes a public key from the box's authorized_keys file" do
        expect(mock_coach).to receive(:remove_public_key).with(dummy_key)
        box.remove_public_key(dummy_key)
      end
    end
  end

  describe '#generate_key_pair' do
    let!(:box) { create :box }
    let!(:mock_key) { double('ssh_key', private_key: 'some-private-key', ssh_public_key: 'some-public-key') }

    it "adds a public key to the box's authorized_keys file" do
      expect(GenerateSSHKey).to receive(:generate) { mock_key }

      expect {
        @key_pair = box.generate_key_pair
      }.to change(box.key_pairs, :count).by(1)

      expect(@key_pair.private_key).to eq('some-private-key')
      expect(@key_pair.public_key).to eq('some-public-key')
    end
  end

  describe '#public_keys' do
    let!(:box) { create :box }

    context 'when box has no public keys' do
      it 'returns an empty array' do
        expect(box.public_keys).to eq []
      end
    end

    context 'when box only has (generated) key pairs' do
      let!(:generated_key_pair) { create :key_pair, box: box, public_key: 'pub', private_key: 'priv' }

      it 'returns the generated public keys' do
        expect(box.public_keys).to eq ['pub']
      end
    end

    context 'when box only has user-uploaded key pairs' do
      let!(:owner) { create :user }
      let!(:uploaded_public_key) { create :public_key, user: owner }
      before { box.owner = owner }

      it 'returns the user-uploaded public keys' do
        expect(box.public_keys).to eq [uploaded_public_key.key]
      end
    end

    context 'when box has both generated key pairs and user-uploaded public keys' do
      let!(:owner) { create :user }
      let!(:generated_key_pair) { create :key_pair, box: box, public_key: 'pub', private_key: 'priv' }
      let!(:uploaded_public_key) { create :public_key, user: owner }
      before { box.owner = owner }

      it 'returns an array containing both generated public keys and user-uploaded public keys' do
        expect(box.public_keys.length).to eq 2
        expect(box.public_keys).to include 'pub'
        expect(box.public_keys).to include uploaded_public_key.key
      end
    end
  end

  describe '#container_name' do
    it 'includes box id and name' do
      box = Box.new(name: "hello")
      box.id = 1
      expect(box.container_name).to eq("hello-1")
    end
  end

  describe '#force_shutdown?' do
    let!(:box) { create :box }

    context 'when box does not have a forced_shutdown_at time set' do
      before { box.force_shutdown_at = nil }

      it 'returns false' do
        expect(box.force_shutdown?).to eq(false)
      end
    end

    context 'when box is not in stopped state' do
      before { box.stub(:stopped?).and_return(false) }

      it 'returns false' do
        expect(box.force_shutdown?).to eq(false)
      end
    end

    context 'when box has a force_shutdown_at time set and is in the stopped state' do
      before do
        box.force_shutdown_at = Time.now
        box.stub(:stopped?).and_return(true)
      end

      it 'returns true' do
        expect(box.force_shutdown?).to eq(true)
      end
    end
  end

  describe '#expected_specs_for_coach' do
    it 'returns a hash that includes memory, disk_space, virtual_memory and cpu_shares keys' do
      box = Box.new
      box.memory = 512
      box.storage = 1000
      box.stub(:expected_virtual_memory) { 1024 }
      box.stub(:expected_cpu_multiplier) { 1 }

      specs = box.expected_specs_for_coach
      expect(specs[:memory]).to eq(512)
      expect(specs[:disk_space]).to eq(1000)
      expect(specs[:virtual_memory]).to eq(1024)
      expect(specs[:cpu_shares]).to eq(1 * Box::BASE_CPU_SHARES)
    end
  end

  describe '#expected_cpu_multiplier' do
    let!(:user) { create :user }
    let!(:box) { create :box, owner: user }

    context 'when user does not have an active subscription plan' do
      before { user.stub(:active_plan).and_return(nil) }

      it 'should default to 1' do
        expect(box.expected_cpu_multiplier).to eq(1)
      end
    end

    context 'when user has an active subscription plan' do
      let!(:plan) { create :plan, cpu_multiplier: 2 }
      before { user.stub(:active_plan).and_return(plan) }

      it 'should be equal to that of the plan' do
        expect(box.expected_cpu_multiplier).to eq(2)
      end
    end
  end

  describe '#expected_virtual_memory' do
    let!(:user) { create :user }
    let!(:box) { create :box, owner: user, memory: 512 }

    context 'when user does not have an active subscription plan' do
      before { user.stub(:active_plan).and_return(nil) }

      it "should be the half the box's memory" do
        expect(box.expected_virtual_memory).to eq(256)
      end
    end

    context 'when user has an active subscription plan' do
      let!(:plan) { create :plan, vmem_multiplier: 2 }
      before { user.stub(:active_plan).and_return(plan) }

      it "should be (box's memory * vmem_multiplier of the plan)" do
        expect(box.expected_virtual_memory).to eq(512 * 2)
      end
    end
  end

  describe '#requires_downgrade?' do
    let!(:box) { create :box }

    context 'when the expected cpu_multiplier is lower than that of the box' do
      before do
        box.cpu_multiplier = 2
        box.stub(:expected_cpu_multiplier).and_return(1)
      end

      it 'should return true' do
        expect(box.requires_downgrade?).to eq(true)
      end
    end

    context 'when the expected cpu_multiplier is higher than that of the box' do
      before do
        box.cpu_multiplier = 2
        box.stub(:expected_cpu_multiplier).and_return(4)
      end

      it 'should return false' do
        expect(box.requires_downgrade?).to eq(false)
      end
    end

    context 'when the expected cpu_multiplier is equal to that of the box' do
      before do
        box.cpu_multiplier = 2
        box.stub(:expected_cpu_multiplier).and_return(2)
      end

      it 'should return false' do
        expect(box.requires_downgrade?).to eq(false)
      end
    end

    context 'when the expected virtual memory is lower than that of the box' do
      before do
        box.virtual_memory = 1024
        box.stub(:expected_virtual_memory).and_return(512)
      end

      it 'should return true' do
        expect(box.requires_downgrade?).to eq(true)
      end
    end

    context 'when the expected virtual memory is higher than that of the box' do
      before do
        box.virtual_memory = 1024
        box.stub(:expected_virtual_memory).and_return(2048)
      end

      it 'should return false' do
        expect(box.requires_downgrade?).to eq(false)
      end
    end

    context 'when the expected virtual memory is equal to that of the box' do
      before do
        box.virtual_memory = 1024
        box.stub(:expected_virtual_memory).and_return(1024)
      end

      it 'should return false' do
        expect(box.requires_downgrade?).to eq(false)
      end
    end
  end

  describe '#requires_upgrade?' do
    let!(:box) { create :box }

    context 'when the expected cpu_multiplier is higher than that of the box' do
      before do
        box.cpu_multiplier = 2
        box.stub(:expected_cpu_multiplier).and_return(3)
      end

      it 'should return true' do
        expect(box.requires_upgrade?).to eq(true)
      end
    end

    context 'when the expected cpu_multiplier is lower than that of the box' do
      before do
        box.cpu_multiplier = 2
        box.stub(:expected_cpu_multiplier).and_return(1)
      end

      it 'should return false' do
        expect(box.requires_upgrade?).to eq(false)
      end
    end

    context 'when the expected cpu_multiplier is equal to that of the box' do
      before do
        box.cpu_multiplier = 2
        box.stub(:expected_cpu_multiplier).and_return(2)
      end

      it 'should return false' do
        expect(box.requires_upgrade?).to eq(false)
      end
    end

    context 'when the expected virtual memory is higher than that of the box' do
      before do
        box.virtual_memory = 1024
        box.stub(:expected_virtual_memory).and_return(2048)
      end

      it 'should return true' do
        expect(box.requires_upgrade?).to eq(true)
      end
    end

    context 'when the expected virtual memory is lower than that of the box' do
      before do
        box.virtual_memory = 1024
        box.stub(:expected_virtual_memory).and_return(512)
      end

      it 'should return false' do
        expect(box.requires_upgrade?).to eq(false)
      end
    end

    context 'when the expected virtual memory is equal to that of the box' do
      before do
        box.virtual_memory = 1024
        box.stub(:expected_virtual_memory).and_return(1024)
      end

      it 'should return false' do
        expect(box.requires_upgrade?).to eq(false)
      end
    end
  end

  describe '#cpu_shares=' do
    let!(:box) { create :box }

    it 'sets the CPU multiplier of the box to (given CPU shares / BASE_CPU_SHARES constant)' do
      stub_const('Box::BASE_CPU_SHARES', 100)

      box.cpu_shares = 200
      expect(box.cpu_multiplier).to eq(2)
      box.cpu_shares = 1000
      expect(box.cpu_multiplier).to eq(10)
      box.cpu_shares = 100
      expect(box.cpu_multiplier).to eq(1)
    end

    it 'handles string arguments' do
      stub_const('Box::BASE_CPU_SHARES', 100)
      box.cpu_shares = '300'

      expect(box.cpu_multiplier).to eq(3)
    end

    it 'sets the CPU multiplier to 1 if given nil' do
      stub_const('Box::BASE_CPU_SHARES', 100)
      box.cpu_shares = nil

      expect(box.cpu_multiplier).to eq(1)
    end

    it 'sets the CPU multiplier to 1 if given an empty string' do
      stub_const('Box::BASE_CPU_SHARES', 100)
      box.cpu_shares = ''

      expect(box.cpu_multiplier).to eq(1)
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
      expect(box.collaborator_status(user_1.username)).to eq Box::COLLABORATOR_EXISTS
    end

    it 'returns Box::ADD_COLLABORATOR when its a user who exists but has not been added as a collaborator' do
      expect(box.collaborator_status(user_2.email)).to eq Box::ADD_COLLABORATOR
    end

    it 'returns Box::INVITE_COLLABORATOR when its a user who exists but has not been added as a collaborator' do
      expect(box.collaborator_status('k@mclov.in')).to eq Box::INVITE_COLLABORATOR
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
          expect(res).to be_persisted
          expect(res).to eq(collaborator2)
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

  describe '#notify_collaborator' do
    let!(:user1)           { create :user }
    let!(:user2)           { create :user }
    let!(:box) { create :box, owner: user1, users: [user1, user2] }

    it 'sends an email to notify of the failure' do
      expect {
        box.notify_collaborator user2.username, user1
      }.to change(Delayed::Job, :count).by(1)

      expect(Delayed::Job.first.handler).to match(/'Notifier'\nmethod_name: :collaboration_notification\nargs:\n- #{user2.id}\n- #{user1.username}\n- #{box.name}\n/)
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

      expect(collaboration_invite.email).to eq("back.to@thefuture.com")
      expect(collaboration_invite).to be_activated
      expect(collaboration_invite.box).to eq(box)
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
        expect(box.n2o_allocation_needed?).to be_truthy
      end
    end

    context 'when record is persisted (update)' do
      before { box.save! }

      context 'when nothing is changed' do
        it 'returns false' do
          expect(box.n2o_allocation_needed?).to be_falsey
        end
      end

      context 'when memory is changed' do
        before { box.memory = 1024 }

        it 'returns true' do
          expect(box.n2o_allocation_needed?).to be_truthy
        end
      end

      context 'when storage is changed' do
        before { box.storage = 10000 }

        it 'returns true' do
          expect(box.n2o_allocation_needed?).to be_truthy
        end
      end

      context 'when other fields are changed' do
        before { box.state = 'stopping' }

        it 'returns false' do
          expect(box.n2o_allocation_needed?).to be_falsey
        end
      end
    end
  end

  describe '#configuration_changed?' do
    let!(:box)   { build :box }

    context 'when memory is changed' do
      before { box.memory = 1024 }

      it 'returns true' do
        expect(box.configuration_changed?).to be_truthy
      end
    end

    context 'when storage is changed' do
      before { box.storage = 10000 }

      it 'returns true' do
        expect(box.configuration_changed?).to be_truthy
      end
    end

    context 'when cpu_multiplier is changed' do
      before { box.cpu_multiplier = 2 }

      it 'returns true' do
        expect(box.configuration_changed?).to be_truthy
      end
    end

    context 'when virtual_memory is changed' do
      before { box.virtual_memory = 1024 }

      it 'returns true' do
        expect(box.configuration_changed?).to be_truthy
      end
    end

    context 'when other fields are changed' do
      before { box.state = 'stopping' }

      it 'returns false' do
        expect(box.configuration_changed?).to be_falsey
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

  describe '.find_all_requiring_restart' do
    let!(:user) { create :user, id: 69 }
    let!(:another_user) { create :user, id: 70 }
    let!(:starting_box) { create :box, owner: user, state: 'starting' }
    let!(:running_box) { create :box, owner: user, state: 'running' }
    let!(:restarting_box) { create :box, owner: user, state: 'restarting' }
    let!(:reconfiguring_box) { create :box, owner: user, state: 'reconfiguring' }
    let!(:someone_elses_running_box) { create :box, owner: another_user, state: 'terminated' }
    let!(:stopped_box) { create :box, owner: user, state: 'stopped' }
    let!(:terminated_box) { create :box, owner: user, state: 'terminated' }

    it 'returns starting, running, restarting, or reconfiguring boxes belonging to the given user ID' do
      expect(Box.find_all_requiring_restart(69)).to match_array([starting_box, running_box, restarting_box, reconfiguring_box])
    end
  end

  describe '.count_by_region' do
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
        expect(Box.count_by_region).to eq({ 'region-1' => 3, 'region-3' => 2, 'region-2' => 1 })
      end
    end

    context "with state set" do
      it "should return a hash which has the number of boxes in each region which are running (sorted in desc order)" do
        expect(Box.count_by_region(state: 'running')).to eq({ 'region-1' => 2, 'region-3' => 1 })
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
        expect(Box.count_by_template).to eq({ 'template-1' => 3, 'template-3' => 2, 'template-2' => 1 })
      end
    end

    context 'with state set' do
      it "should return a hash which has the number of boxes in each region which are running (sorted in desc order)" do
        expect(Box.count_by_template(state: 'running')).to eq({ 'template-1' => 2, 'template-3' => 1 })
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
        expect(Box.count_by_memory).to eq({ 1024 => 3, 384 => 2, 512 => 1 })
      end
    end

    context "with state set" do
      it "should return a hash which has the number of boxes in each memory block (sorted in desc order)" do
        expect(Box.count_by_memory(state: 'running')).to eq({ 1024 => 2, 384 => 1 })
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
        expect(Box.count_by_storage).to eq({ 1000 => 3, 250 => 2, 500 => 1 })
      end
    end

    context "with state set" do
      it "should return a hash which has the number of boxes in each storage block (sorted in desc order)" do
        expect(Box.count_by_storage(state: 'running')).to eq({ 1000 => 2, 250 => 1 })
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
    let!(:box7)     { create :box, state: 'born' }
    let!(:box8)     { create :box, state: 'provisioning' }
    let!(:box9)     { create :box, state: 'starting' }
    let!(:box10)     { create :box, state: 'stopping' }
    let!(:box11)     { create :box, state: 'stopped' }
    let!(:box12)     { create :box, state: 'terminating' }
    let!(:box13)     { create :box, state: 'restarting' }
    let!(:box14)     { create :box, state: 'reconfiguring' }
    let!(:box15)     { create :box, state: 'failed' }
    let!(:box16)     { create :box, state: 'migrating' }

    describe ".running_count" do
      it "should return the total count of running boxes" do
        expect(Box.running_count).to eql('count' => 3)
      end
    end

    describe ".unterminated_count" do
      it "should return the total count of running boxes" do
        expect(Box.unterminated_count).to eql('count' => 15)
      end
    end

    describe ".total_count" do
      it "should return the total count of all boxes" do
        expect(Box.total_count).to eql('count' => 16)
      end
    end

    describe ".born_count" do
      it "should return the total count of born boxes" do
        expect(Box.born_count).to eql('count' => 3)
      end
    end

    describe ".terminated_count" do
      it "should return the total count of terminated boxes" do
        expect(Box.terminated_count).to eql('count' => 1)
      end
    end

    describe ".failed_count" do
      it "should return the total count of failed boxes" do
        expect(Box.failed_count).to eql('count' => 1)
      end
    end

    describe ".starting_count" do
      it "should return the total count of starting boxes" do
        expect(Box.starting_count).to eql('count' => 1)
      end
    end

    describe ".provisioning_count" do
      it "should return the total count of provisioning boxes" do
        expect(Box.provisioning_count).to eql('count' => 1)
      end
    end

    describe ".stopping_count" do
      it "should return the total count of stopping boxes" do
        expect(Box.stopping_count).to eql('count' => 1)
      end
    end

    describe ".stopped_count" do
      it "should return the total count of stopped boxes" do
        expect(Box.stopped_count).to eql('count' => 1)
      end
    end

    describe ".terminating_count" do
      it "should return the total count of terminating boxes" do
        expect(Box.terminating_count).to eql('count' => 1)
      end
    end

    describe ".restarting_count" do
      it "should return the total count of restarting boxes" do
        expect(Box.restarting_count).to eql('count' => 1)
      end
    end

    describe ".reconfiguring_count" do
      it "should return the total count of reconfiguring boxes" do
        expect(Box.reconfiguring_count).to eql('count' => 1)
      end
    end

    describe ".migrating_count" do
      it "should return the total count of migrating boxes" do
        expect(Box.migrating_count).to eql('count' => 1)
      end
    end
  end

  describe '#start_migration' do
    let!(:mock_coach) { instance_double('Coach') }
    let!(:box)        { create :box }

    before do
      box.stub(:coach) { mock_coach }
      box.stub :push_box_updated_message
    end

    it 'migrate the box from current host' do
      expect(mock_coach).to receive(:migrate)
      box.start_migration
    end

    it 'marks the box as migrating' do
      allow(mock_coach).to receive(:migrate)
      expect {
        box.start_migration
      }.to change { box.reload.state }.to("migrating")
    end

    it 'updates state of the box' do
      allow(mock_coach).to receive(:migrate)
      expect(box).to receive(:push_box_updated_message)
      box.start_migration
    end
  end

  describe '#finish_migration' do
    let!(:box) { create :box }

    it 'updates the state and version' do
      box.update_attribute :state, 'migrating'
      expect(box).to receive :push_box_updated_message
      box.finish_migration
      box.reload
      expect(box.state).to eq("stopped")
      expect(box.version).to eq("cersei")
    end
  end

  describe '#update_auth' do
    let!(:box) { create :box }
    let!(:mock_coach) { instance_double('Coach') }

    before do
      mock_coach.stub :update_auth
      box.stub(:coach) { mock_coach }
    end

    it 'changes auth username and password' do
      box.update_auth 'admin', 'password'
      box.reload
      expect(box.auth_username).to eq('admin')
      expect(box.auth_password).to eq('password')
    end

    context 'when username or password provided is blank' do
      it 'sets auth username and password as nil' do
        box.update_auth '', ''
        box.reload
        expect(box.auth_username).to be_nil
        expect(box.auth_password).to be_nil
      end
    end

    it 'calls Coach to update the username/password cache' do
      expect(mock_coach).to receive(:update_auth)
      box.update_auth 'admin', 'password'
    end
  end

  describe '#premium?' do
    let!(:user) { create :user }
    let!(:box) { create :box, owner: user }

    context 'when owner of the box has an active subscription' do
      let!(:plan) { create :plan }
      before { user.stub(:active_plan).and_return(plan) }

      it 'should return true' do
        expect(box.premium?).to eq(true)
      end
    end

    context 'when owner of the box does not have an active subscription' do
      it 'should return false' do
        expect(box.premium?).to eq(false)
      end
    end
  end
end
