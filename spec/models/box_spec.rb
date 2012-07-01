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
    let!(:box) { create :box }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:region_id) }

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
    let!(:box_1) { create :box }
    let!(:box_2) { create :box, state: 'terminated' }
    let!(:box_3) { create :box, state: 'suspended'  }

    describe '.unterminated' do
      it "should return all boxes which don't have the state set to 'terminated'" do
        Box.unterminated.to_a.should =~ [box_1, box_3]
      end
    end
  end

  describe 'delegates' do
    let!(:region_1) { create :region, box_server_uri: 'https://boxserver.example.com:1234' }
    let!(:box_1)    { create :box, region: region_1 }

    describe "box_server_uri" do
      it "should return the box server uri of the region that it belongs to" do
        box_1.box_server_uri.should == 'https://boxserver.example.com:1234'
      end
    end
  end

  context 'before save' do
    it 'downcases name' do
      box = build :box, name: 'Fragrant-Wind-69'
      box.save
      box.name.should == 'fragrant-wind-69'
    end
  end

  context 'before create' do
    it 'adds owner to users' do
      user = create :user
      box = create :box, owner: user
      box.users.should == [user]
    end

    it 'generates a secret key' do
      box1 = create :box
      box2 = create :box
      box3 = create :box
      box1.key.should_not == box2.key
      box2.key.should_not == box3.key
      box3.key.should_not == box1.key
    end
  end

  context 'after create' do
    it 'enqueues a provision box job' do
      box = build :box
      ProvisionBoxJob.should_receive(:new) do |*args|
        args.should == [box.id]
      end.and_return(:provision_box_job)

      Delayed::Job.should_receive(:enqueue).with(:provision_box_job)
      box.save
    end
  end

  describe '#boxer' do
    let!(:owner) { create :user }
    let!(:collaborator) { create :user }
    let!(:random_user) { create :user }
    let!(:key1) { create :public_key, user: owner }
    let!(:key2) { create :public_key, user: owner }
    let!(:region) { create :region }
    let!(:box_host) { create :box_host, region: region }
    let!(:box) { create :box, owner: owner, users: [owner, collaborator], region: region }

    it 'memoizes and returns a new Boxer instance' do
      mock_boxer = double('boxer')
      Boxer.stub(:new) do |options|
        options[:hostname].should == box.name
        options[:region].should == region.name
        options[:public_keys].should =~ [key1.key, key2.key]
        options[:ec2_host].should == box_host.host
        options[:ec2_key].should == region.keypair
        options[:box_id].should == box.id
        options[:box_key].should == box.key
        options[:user_ids].should =~ [owner.id, collaborator.id]
        mock_boxer
      end
      boxer = box.boxer
      boxer.should == mock_boxer
      box.instance_variable_get(:@boxer).should == mock_boxer
    end
  end

  describe 'state machine' do
    let(:box_template)  { create :box_template, image: 'rails' }
    let!(:box)          { create :box, host: nil, port: nil, box_template: box_template }
    let!(:mock_boxer)   { double('boxer') }
    let!(:key_pair)     { create :key_pair, private_key: 'private-key', public_key: 'public-key' }

    before { box.stub!(:boxer) { mock_boxer } }

    describe '#provision' do
      it 'calls Boxer#provision_box and transitions from "provisioning" to "stopped" state' do
        box.should_receive :push_box_updated_message
        box.should_receive(:generate_key_pair).and_return(key_pair)

        mock_boxer.should_receive(:provision_box).with('rails') do
          { host: '201.202.203.204', ssh_port: '12345', tty_port: '54321' }
        end

        box.should_receive(:add_public_key).with('public-key')

        expect {
          box.provision!
        }.to change { box.state }.from('provisioning').to('stopped')

        box.host.should == '201.202.203.204'
        box.port.should == 12345
        box.tty_port.should == 54321
      end
    end

    describe '#enqueue_start' do
      before do
        box.update_attribute :state, 'stopped'
      end

      it 'enqueues a start box job' do
        box.should_receive :push_box_updated_message
        StartBoxJob.should_receive(:new).with(box.id).and_return(:box_job)
        Delayed::Job.should_receive(:enqueue).with(:box_job)

        expect {
          box.enqueue_start!
        }.to change { box.state }.from('stopped').to('starting')

      end
    end

    describe '#start' do
      before do
        box.update_attribute :state, 'starting'
      end

      it 'starts the box' do
        box.should_receive :push_box_updated_message
        mock_boxer.should_receive(:start_box)
        expect {
          box.start!
        }.to change { box.state }.from('starting').to('running')
      end
    end

    describe '#enqueue_suspend' do
      before do
        box.update_attribute :state, 'running'
      end

      it 'enqueues a suspend box job' do
        box.should_receive :push_box_updated_message
        SuspendBoxJob.should_receive(:new).with(box.id).and_return(:suspend_box_job)
        Delayed::Job.should_receive(:enqueue).with(:suspend_box_job)

        expect {
          box.enqueue_suspend!
        }.to change { box.state }.from('running').to('suspending')
      end
    end

    describe '#suspend' do
      before do
        box.update_attribute :state, 'suspending'
      end

      it 'suspends the box' do
        box.should_receive :push_box_updated_message
        mock_boxer.should_receive(:freeze_box)
        expect {
          box.suspend!
        }.to change { box.state }.from('suspending').to('suspended')
      end
    end

    describe '#enqueue_resume' do
      before do
        box.update_attribute :state, 'suspended'
      end

      it 'enqueues a resume box job' do
        box.should_receive :push_box_updated_message
        ResumeBoxJob.should_receive(:new).with(box.id).and_return(:resume_box_job)
        Delayed::Job.should_receive(:enqueue).with(:resume_box_job)

        expect {
          box.enqueue_resume!
        }.to change { box.state }.from('suspended').to('resuming')
      end
    end

    describe '#resume' do
      before { box.update_attribute :state, 'resuming' }

      it 'resumes the box' do
        box.should_receive :push_box_updated_message
        mock_boxer.should_receive(:unfreeze_box)
        expect {
          box.resume!
        }.to change { box.state }.from('resuming').to('running')
      end
    end

    describe '#enqueue_stop' do
      before { box.update_attribute :state, 'running' }

      it 'enqueues a stop box job' do
        box.should_receive :push_box_updated_message
        StopBoxJob.should_receive(:new).with(box.id).and_return(:stop_box_job)
        Delayed::Job.should_receive(:enqueue).with(:stop_box_job)

        expect {
          box.enqueue_stop!
        }.to change { box.state }.from('running').to('stopping')
      end
    end

    describe '#stop' do
      before { box.update_attribute :state, 'stopping' }

      it 'stops the box' do
        box.should_receive :push_box_updated_message
        mock_boxer.should_receive(:shut_down_box)
        expect {
          box.stop!
        }.to change { box.state }.from('stopping').to('stopped')
      end
    end

    describe '#enqueue_terminate' do
      before { box.update_attribute :state, 'stopped' }

      it 'enqueues a terminate box job' do
        box.should_receive :push_box_updated_message
        TerminateBoxJob.should_receive(:new).with(box.id).and_return(:terminate_box_job)
        Delayed::Job.should_receive(:enqueue).with(:terminate_box_job)

        expect {
          box.enqueue_terminate!
        }.to change { box.state }.from('stopped').to('terminating')
      end
    end

    describe '#terminate' do
      before { box.update_attribute :state, 'terminating' }

      it 'terminates the box' do
        box.should_receive :push_box_updated_message
        mock_boxer.should_receive(:terminate_box)
        expect {
          box.terminate!
        }.to change { box.state }.from('terminating').to('terminated')
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

  describe '#{add,remove}_public_key' do
    let!(:box) { create :box }
    let!(:mock_boxer) { double('boxer') }
    let!(:dummy_key) { 'ssh-rsa S0m3DummYk3Y key@example.com' }

    before { box.stub!(:boxer) { mock_boxer } }

    describe '#add_public_key' do
      it "adds a public key to the box's authorized_keys file" do
        mock_boxer.should_receive(:add_key).with(dummy_key)
        box.add_public_key(dummy_key)
      end
    end

    describe '#remove_public_key' do
      it "removes a public key from the box's authorized_keys file" do
        mock_boxer.should_receive(:delete_key).with(dummy_key)
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
      SSHKey.should_receive(:generate).with(type: "RSA", bits: 2048).and_return(mock_key)

      expect {
        @key_pair = box.generate_key_pair
      }.to change(box.key_pairs, :count).by(1)

      @key_pair.private_key.should == 'some-private-key'
      @key_pair.public_key.should == 'some-public-key'
    end
  end
end
