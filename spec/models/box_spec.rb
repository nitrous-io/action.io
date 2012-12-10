# coding: utf-8

require 'spec_helper'

describe Box do
  it { should allow_mass_assignment_of :name }
  it { should_not allow_mass_assignment_of :host }
  it { should_not allow_mass_assignment_of :port }
  it { should_not allow_mass_assignment_of :tty_port }
  it { should_not allow_mass_assignment_of :state }
  it { should_not allow_mass_assignment_of :key }
  it { should_not allow_mass_assignment_of :box_template_id }
  it { should_not allow_mass_assignment_of :owner_id }
  it { should_not allow_mass_assignment_of :region_id }

  it { should have_many(:box_admins).dependent(:destroy) }
  it { should have_many(:key_pairs).dependent(:destroy) }

  it { should have_many(:users).through(:box_admins) }
  it { should belong_to(:box_template) }
  it { should belong_to(:owner).class_name('User') }
  it { should belong_to(:region) }

  describe 'validations' do
    let(:box) { create :box }

    before { Box.any_instance.stub :push_box_added_message }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:region_id) }
    it { should validate_presence_of(:box_template_id) }

    it { should validate_uniqueness_of(:name) }
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

    it 'validates presence of owner only when box is a new record' do
       box.owner = nil
       box.should be_valid
       new_box = build :box, owner: nil
       new_box.should_not be_valid
    end
  end

  describe 'scopes' do
    before do
      Box.any_instance.stub :push_box_added_message
      @box_1 = create :box
      @box_2 = create :box, state: 'terminated'
      @box_3 = create :box, state: 'running'
    end

    context '.unterminated' do
      it "should return all boxes which don't have the state set to 'terminated'" do
        Box.unterminated.to_a.should =~ [@box_1, @box_3]
      end
    end

    context '.running' do
      it "should return all boxes which don't have the state set to 'terminated'" do
        Box.running.to_a.should == [@box_3]
      end
    end
  end

  describe 'delegates' do
    let(:region_1) { create :region, box_server_uri: 'https://boxserver.example.com:1234' }
    let(:box_1)    { create :box, region: region_1 }

    before { Box.any_instance.stub :push_box_added_message }

    context "box_server_uri" do
      it "should return the box server uri of the region that it belongs to" do
        box_1.box_server_uri.should == 'https://boxserver.example.com:1234'
      end
    end
  end

  context 'before save' do
    before { Box.any_instance.stub :push_box_added_message }

    it 'downcases name' do
      box = build :box, name: 'Fragrant-Wind-69'
      box.save
      box.name.should == 'fragrant-wind-69'
    end
  end

  context 'before create' do
    before { Box.any_instance.stub :push_box_added_message }

    it 'adds owner to users' do
      user = create :user
      box = create :box, owner: user
      box.users.should == [user]
    end
  end

  context 'after create' do
    it 'creates a key pair for the box' do
      box = build :box
      box.should_receive :generate_key_pair
      box.should_receive :push_box_added_message
      box.save
    end
  end

  describe '#coach' do
    it 'memoizes and returns a new Coach instance' do
      mock_coach = double('coach')
      Box.any_instance.stub :enqueue_provision!
      Box.any_instance.stub :push_box_added_message

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
    let(:mock_coach)    { double('coach') }
    let(:box)           { create :box }

    before do
      Box.any_instance.stub :push_box_added_message
      box.stub!(:coach) { mock_coach }
    end

    describe '#enqueue_provision' do
      it 'enqueues a provision job' do
        ProvisionBoxJob.should_receive(:new) do |*args|
          args.should == [box.id]
        end.and_return(:provision_box_job)

        Delayed::Job.should_receive(:enqueue).with(:provision_box_job)
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
            StartBoxJob.should_receive(:new) do |*args|
              args.should == [box.id]
            end.and_return(:start_box_job)

            Delayed::Job.should_receive(:enqueue).with(:start_box_job)
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
        Box.any_instance.stub :push_box_added_message
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
      before do
        Box.any_instance.stub :push_box_added_message
        box.update_attribute :state, 'running'
      end

      it 'enqueues a stop box job' do
        StopBoxJob.should_receive(:new) do |*args|
          args.should == [box.id]
        end.and_return(:stop_box_job)

        Delayed::Job.should_receive(:enqueue).with(:stop_box_job)
        box.should_receive :push_box_updated_message

        expect {
          box.enqueue_stop!
        }.to change { box.state }.from('running').to('stopping')
      end
    end

    describe '#stop' do
      before do
        Box.any_instance.stub :push_box_added_message
        box.update_attribute :state, 'stopping'
      end

      it 'stops the box' do
        box.should_receive :push_box_updated_message
        expect {
          box.stop!
        }.to change { box.state }.from('stopping').to('stopped')
      end
    end

    describe '#enqueue_restart' do
      before do
        Box.any_instance.stub :push_box_added_message
        box.update_attribute :state, 'running'
      end

      it 'enqueues a restart box job' do
        RestartBoxJob.should_receive(:new) do |*args|
          args.should == [box.id]
        end.and_return(:restart_box_job)

        Delayed::Job.should_receive(:enqueue).with(:restart_box_job)
        box.should_receive :push_box_updated_message

        expect {
          box.enqueue_restart!
        }.to change { box.state }.from('running').to('restarting')
      end
    end

    describe '#restart' do
      before do
        Box.any_instance.stub :push_box_added_message
        box.update_attribute :state, 'restarting'
      end

      it 'restarts the box' do
        box.should_receive :push_box_updated_message
        expect {
          box.restart!
        }.to change { box.state }.from('restarting').to('running')
      end
    end

    describe '#enqueue_terminate' do
      before do
        Box.any_instance.stub :push_box_added_message
        box.update_attribute :state, 'stopped'
      end

      it 'enqueues a terminate box job' do
        TerminateBoxJob.should_receive(:new) do |*args|
          args.should == [box.id]
        end.and_return(:terminate_box_job)

        Delayed::Job.should_receive(:enqueue).with(:terminate_box_job)
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
    end
  end

  describe '#push_box_updated_message' do
    let(:user1) { create :user }
    let(:user2) { create :user }
    let(:user3) { create :user }

    before { Box.any_instance.stub :push_box_added_message }

    it 'pushes aio:box_updated notification' do
      box = create :box, owner: user1, users: [user1, user3]
      channel = double('channel')
      [user1, user3].each do |user|
        Pusher.should_receive(:[]).with("private-user-#{user.id}") { channel }
        channel.should_receive(:trigger).ordered.with('aio:box_updated', box.serialize_as_hash)
      end
      box.push_box_updated_message
    end
  end

  describe '#push_box_added_message' do
    let(:user1)   { create :user }
    let(:user2)   { create :user }
    let(:user3)   { create :user }
    let(:box)     { create :box, owner: user1, users: [user1, user3] }
    let(:channel) { double('channel') }

    it 'pushes aio:box_added notification' do
      Pusher.should_receive(:[]).with("private-user-#{user1.id}") { channel }
      channel.should_receive(:trigger).ordered.with('aio:box_added', box.serialize_as_hash)
    end
  end

  describe '#{add,remove}_public_key' do
    let(:box) { create :box }
    let!(:mock_coach) { double('coach') }
    let!(:dummy_key) { 'ssh-rsa S0m3DummYk3Y key@example.com' }

    before do
      Box.any_instance.stub :push_box_added_message
      box.stub!(:coach) { mock_coach }
    end

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
    let(:box)         { create :box }
    let!(:mock_boxer) { double('boxer') }
    let!(:mock_key)   { double('ssh_key', private_key: 'some-private-key', ssh_public_key: 'some-public-key') }

    before do
      Box.any_instance.stub :push_box_added_message
      box.stub!(:boxer) { mock_boxer }
    end

    it "adds a public key to the box's authorized_keys file" do
      GenerateSSHKey.should_receive(:generate) { mock_key }

      expect {
        @key_pair = box.generate_key_pair
      }.to change(box.key_pairs, :count).by(1)

      @key_pair.private_key.should == 'some-private-key'
      @key_pair.public_key.should == 'some-public-key'
    end
  end
end
