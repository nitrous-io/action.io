# coding: utf-8

require 'spec_helper'

describe Box do
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :region }
  it { should_not allow_mass_assignment_of :host }
  it { should_not allow_mass_assignment_of :port }
  it { should_not allow_mass_assignment_of :status }
  it { should_not allow_mass_assignment_of :template_id }

  it { should have_many(:box_admins).dependent(:destroy) }
  it { should have_many(:users).through(:box_admins) }
  it { should belong_to(:box_template) }
  it { should belong_to(:owner).class_name('User') }

  describe 'validations' do
    let!(:box) { create :box }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:region) }

    it { should validate_uniqueness_of(:name) }

    it { should allow_value(*Settings.valid_regions).for(:region) }
    it { should_not allow_value('china').for(:region) }

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

  it 'downcases name before saving' do
    box = build :box, name: 'Fragrant-Wind-69'
    box.save
    box.name.should == 'fragrant-wind-69'
  end

  it 'adds owner to users on create' do
    user = create :user
    box = create :box, owner: user
    box.users.should == [user]
  end

  it 'enqueues a provision box job after create' do
    box = build :box
    Resque.should_receive(:enqueue) do |*args|
      args.should == [ProvisionBoxJob, box.id]
    end
    box.save
  end

  describe '#boxer' do
    let!(:box) { create :box }

    it 'memoizes and returns a new Action::Boxer instance' do
      mock_boxer = double('boxer')
      Action::Boxer.stub(:new).with(box.owner.username, box.name, box.region) { mock_boxer }
      boxer = box.boxer
      boxer.should == mock_boxer
      box.instance_variable_get(:@boxer).should == mock_boxer
    end
  end

  describe 'state machine' do
    let!(:box) { create :box, host: nil, port: nil }
    let!(:mock_boxer) { double('boxer') }
    subject { box }

    before do
      box.stub!(:boxer) { mock_boxer }
    end

    describe '#provision' do
      it 'calls Boxer#provision_box and transitions from "new" to "stopped" state' do
        mock_boxer.should_receive(:provision_box).with('rails') do
          { ip: '1.2.3.4', port: '12345' }
        end
        expect {
          box.provision!
        }.to change { box.status }.from('new').to('stopped')
        box.host.should == '1.2.3.4'
        box.port.should == '12345'
      end
    end

    describe '#start' do
      before { box.update_attribute :status, 'stopped' }

      specify do
        mock_boxer.should_receive(:start_box)
        expect {
          box.start!
        }.to change { box.status }.from('stopped').to('running')
      end
    end

    describe '#stop' do
      before { box.update_attribute :status, 'running' }

      specify do
        mock_boxer.should_receive(:stop_box)
        expect {
          box.stop!
        }.to change { box.status }.from('running').to('stopped')
      end
    end

    describe '#terminate' do
      before { box.update_attribute :status, 'stopped' }

      specify do
        mock_boxer.should_receive(:terminate_box)
        expect {
          box.terminate!
        }.to change { box.status }.from('stopped').to('terminated')
      end
    end
  end
end
