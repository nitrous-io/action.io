# coding: utf-8

require 'spec_helper'

describe Box do
  it { should allow_mass_assignment_of :name }
  it { should_not allow_mass_assignment_of :host }
  it { should_not allow_mass_assignment_of :port }
  it { should_not allow_mass_assignment_of :state }
  it { should_not allow_mass_assignment_of :box_template_id }
  it { should_not allow_mass_assignment_of :owner_id }
  it { should_not allow_mass_assignment_of :region_id }

  it { should have_many(:box_admins).dependent(:destroy) }
  it { should have_many(:users).through(:box_admins) }
  it { should belong_to(:box_template) }
  it { should belong_to(:owner).class_name('User') }
  it { should belong_to(:region) }

  describe 'validations' do
    let!(:box) { create :box }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:region_id) }

    it { should validate_uniqueness_of(:name) }

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
  end

  context 'after create' do
    it 'enqueues a provision box job' do
      box = build :box
      Resque.should_receive(:enqueue) do |*args|
        args.should == [ProvisionBoxJob, box.id]
      end
      box.save
    end
  end

  describe '#boxer' do
    let!(:owner) { create :user }
    let!(:key1) { create :public_key, user: owner }
    let!(:key2) { create :public_key, user: owner }
    let!(:region) { create :region }
    let!(:box_host) { create :box_host, region: region }
    let!(:box) { create :box, owner: owner, region: region }

    it 'memoizes and returns a new Action::Boxer instance' do
      mock_boxer = double('boxer')
      Action::Boxer.stub(:new) do |options|
        options[:username].should == owner.username
        options[:hostname].should == box.name
        options[:region].should == region.name
        options[:public_keys].should =~ [key1.key, key2.key]
        options[:ec2_host].should == box_host.host
        options[:ec2_key].should == region.keypair
        mock_boxer
      end
      boxer = box.boxer
      boxer.should == mock_boxer
      box.instance_variable_get(:@boxer).should == mock_boxer
    end
  end

  describe 'state machine' do
    let(:box_template) { create :box_template, image: 'rails' }
    let!(:box) { create :box, host: nil, port: nil, box_template: box_template }
    let!(:mock_boxer) { double('boxer') }
    subject { box }

    before { box.stub!(:boxer) { mock_boxer } }

    describe '#provision' do
      it 'calls Boxer#provision_box and transitions from "new" to "stopped" state' do
        mock_boxer.should_receive(:provision_box).with('rails') do
          { ip: '201.202.203.204', port: '12345' }
        end
        expect {
          box.provision!
        }.to change { box.state }.from('new').to('stopped')
        box.host.should == '201.202.203.204'
        box.port.should == '12345'
      end
    end

    describe '#enqueue_start' do
      before { box.update_attribute :state, 'stopped' }

      it 'enqueues a start box job' do
        Resque.should_receive(:enqueue).with(StartBoxJob, box.id)
        expect {
          box.enqueue_start!
        }.to change { box.state }.from('stopped').to('starting')
      end
    end

    describe '#start' do
      before { box.update_attribute :state, 'starting' }

      it 'starts the box' do
        mock_boxer.should_receive(:start_box)
        expect {
          box.start!
        }.to change { box.state }.from('starting').to('running')
      end
    end

    #describe '#enqueue_suspend' do
      #before { box.update_attribute :state, 'running' }

      #it 'enqueues a suspend box job' do
        #Resque.should_receive(:enqueue).with(SuspendBoxJob, box.id)
        #expect {
          #box.enqueue_suspend!
        #}.to change { box.state }.from('running').to('suspending')
      #end
    #end

    #describe '#suspend' do
      #before { box.update_attribute :state, 'suspending' }

      #it 'suspends the box' do
        #mock_boxer.should_receive(:suspend_box)
        #expect {
          #box.suspend!
        #}.to change { box.state }.from('suspending').to('suspended')
      #end
    #end

    #describe '#enqueue_resume' do
      #before { box.update_attribute :state, 'suspended' }

      #it 'enqueues a resume box job' do
        #Resque.should_receive(:enqueue).with(ResumeBoxJob, box.id)
        #expect {
          #box.enqueue_resume!
        #}.to change { box.state }.from('suspended').to('resuming')
      #end
    #end

    #describe '#resume' do
      #before { box.update_attribute :state, 'resuming' }

      #it 'resumes the box' do
        #mock_boxer.should_receive(:resume_box)
        #expect {
          #box.resume!
        #}.to change { box.state }.from('resuming').to('running')
      #end
    #end

    describe '#enqueue_stop' do
      before { box.update_attribute :state, 'running' }

      it 'enqueues a stop box job' do
        Resque.should_receive(:enqueue).with(StopBoxJob, box.id)
        expect {
          box.enqueue_stop!
        }.to change { box.state }.from('running').to('stopping')
      end
    end

    describe '#stop' do
      before { box.update_attribute :state, 'stopping' }

      it 'stops the box' do
        mock_boxer.should_receive(:stop_box)
        expect {
          box.stop!
        }.to change { box.state }.from('stopping').to('stopped')
      end
    end

    describe '#enqueue_terminate' do
      before { box.update_attribute :state, 'stopped' }

      it 'enqueues a terminate box job' do
        Resque.should_receive(:enqueue).with(TerminateBoxJob, box.id)
        expect {
          box.enqueue_terminate!
        }.to change { box.state }.from('stopped').to('terminating')
      end
    end

    describe '#terminate' do
      before { box.update_attribute :state, 'terminating' }

      it 'terminates the box' do
        mock_boxer.should_receive(:terminate_box)
        expect {
          box.terminate!
        }.to change { box.state }.from('terminating').to('terminated')
      end
    end
  end
end
