require 'spec_helper'

describe Region do
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :description }
  it { should allow_mass_assignment_of :coach_uri }
  it { should allow_mass_assignment_of :box_server_uri }

  it { should have_many(:boxes).dependent(:nullify) }

  describe 'validations' do
    let!(:region) { create :region }

    it { should validate_presence_of :name }
    it { should validate_presence_of :description }

    it { should validate_uniqueness_of :name }
  end

  describe 'scopes' do
    describe '.enabled' do
      let!(:region1) { create :region, enabled: true }
      let!(:region2) { create :region, enabled: true }
      let!(:region3) { create :region }

      subject { Region.enabled.all }

      it { should == [region1, region2] }
    end
  end

  describe 'state machine' do
    let!(:region){ create :region }

    describe '#go_down' do
      before do
        region.update_attribute :state, 'going_down'
      end

      it 'changes region state to down' do
        region.should_receive :push_maintainence_state_message
        expect {
          region.go_down!
        }.to change { region.state }.from('going_down').to('down')
      end
    end

    describe '#go_up' do
      before do
        region.update_attribute :state, 'down'
      end

      it 'changes region state to up' do
        region.should_receive :push_maintainence_state_message
        expect {
          region.go_up!
        }.to change { region.state }.from('down').to('up')
      end
    end

    describe '#start_to_go_down' do
      before do
        region.update_attribute :state, 'up'
      end

      it 'changes region state to up' do
        region.should_receive :push_maintainence_state_message
        expect {
          region.start_to_go_down!
        }.to change { region.state }.from('up').to('going_down')
      end
    end

    describe '#disable_box_creation!' do
      before do
        region.update_attribute :state, 'up'
      end

      it 'changes region state to box_creation_disabled' do
        region.should_receive :push_maintainence_state_message
        expect {
          region.disable_box_creation!
        }.to change { region.state }.from('up').to('box_creation_disabled')
      end
    end

    describe '#enable_box_creation!' do
      before do
        region.update_attribute :state, 'box_creation_disabled'
      end

      it 'changes region state to up' do
        region.should_receive :push_maintainence_state_message
        expect {
          region.enable_box_creation!
        }.to change { region.state }.from('box_creation_disabled').to('up')
      end
    end
  end

  describe '#push_maintainence_state_message' do
    let!(:region) { create :region }

    it 'pushes aio:region_status notification' do
      channel = double('channel')
      Pusher.should_receive(:[]).with("maintenance-channel") { channel }
      channel.should_receive(:trigger).ordered.with('aio:region_status', { region_id: region.id, state: region.state })

      region.push_maintainence_state_message
    end
  end
end
