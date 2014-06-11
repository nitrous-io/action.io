require 'spec_helper'

describe Region do
  it { should allow_mass_assignment_of :name }
  it { should allow_mass_assignment_of :description }
  it { should allow_mass_assignment_of :coach_uri }
  it { should allow_mass_assignment_of :box_server_uri }
  it { should allow_mass_assignment_of :version }
  it { should allow_mass_assignment_of :ssl_enabled }

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

      subject { Region.enabled.load }

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
        expect(region).to receive :push_maintainence_state_message
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
        expect(region).to receive :push_maintainence_state_message
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
        expect(region).to receive :push_maintainence_state_message
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
        expect(region).to receive :push_maintainence_state_message
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
        expect(region).to receive :push_maintainence_state_message
        expect {
          region.enable_box_creation!
        }.to change { region.state }.from('box_creation_disabled').to('up')
      end
    end
  end

  describe '#push_maintainence_state_message' do
    let!(:region) { create :region }

    it 'pushes aio:region_status notification' do
      channel = instance_double('Pusher::Channel')

      expect(Shover).to receive(:broadcast).with('aio:region_status', { region_id: region.id, state: region.state })

      expect(Pusher).to receive(:[]).with("maintenance-channel") { channel }
      expect(channel).to receive(:trigger).ordered.with('aio:region_status', { region_id: region.id, state: region.state })

      region.push_maintainence_state_message
    end
  end

  describe '#can_create_boxes?' do
    let!(:region) { create :region, enabled: true }

    context 'when region is down' do
      before { region.update_attribute('state', 'down') }

      it 'returns false' do
        expect(region.can_create_boxes?).to be_falsey
      end
    end

    context 'when region is going down' do
      before { region.update_attribute('state', 'going_down') }

      it 'returns false' do
        expect(region.can_create_boxes?).to be_falsey
      end
    end

    context 'when box creation is disabled in region' do
      before { region.update_attribute('state', 'box_creation_disabled') }

      it 'returns false' do
        expect(region.can_create_boxes?).to be_falsey
      end
    end

    context 'when region is up' do
      before { region.update_attribute('state', 'up') }

      it 'returns true' do
        expect(region.can_create_boxes?).to be_truthy
      end
    end

    context 'when region is disabled' do
      before { region.update_attribute('enabled', false) }

      it 'returns false' do
        expect(region.can_create_boxes?).to be_falsey
      end
    end
  end

  describe '.recommended_for' do
    let!(:us_west_1) { create :region, name: 'us-west-1', enabled: true }
    let!(:us_east_1) { create :region, name: 'us-east-1', enabled: true }

    context 'when given a continent that has a corresponding AWS region name' do
      before do
        expect(AwsRegion).to receive(:for_continent).with('NA').and_return('us-west-1')
      end

      it 'should return the region' do
        expect(Region.recommended_for(continent: 'NA')).to eq(us_west_1)
      end
    end

    context 'when given a continent that has no corresponding AWS region name' do
      before do
        expect(AwsRegion).to receive(:for_continent).with('NA').and_return(nil)
      end

      it 'should return nil' do
        expect(Region.recommended_for(continent: 'NA')).to be_nil
      end
    end

    context 'when given a country that has a corresponding AWS region name' do
      before do
        expect(AwsRegion).to receive(:for_country).with('US').and_return('us-west-1')
      end

      it 'should return the region' do
        expect(Region.recommended_for(country: 'US')).to eq(us_west_1)
      end
    end

    context 'when given a country that has no corresponding AWS region name' do
      before do
        expect(AwsRegion).to receive(:for_country).with('US').and_return(nil)
      end

      it 'should return the region' do
        expect(Region.recommended_for(country: 'US')).to be_nil
      end
    end

    context 'when given a country and state that has a corresponding AWS region name' do
      before do
        expect(AwsRegion).to receive(:for_state).with(country: 'US', state: 'CA').and_return('us-west-1')
      end

      it 'should return the region' do
        expect(Region.recommended_for(country: 'US', state: 'CA')).to eq(us_west_1)
      end
    end

    context 'when given a country and state that has no corresponding AWS region name' do
      before do
        expect(AwsRegion).to receive(:for_state).with(country: 'US', state: 'CA').and_return(nil)
        expect(AwsRegion).to receive(:for_country).with('US').and_return(nil)
      end

      it 'should return the region' do
        expect(Region.recommended_for(country: 'US', state: 'CA')).to be_nil
      end
    end

    context 'when the AWS region name returned does not match any of the existing regions' do
      before do
        expect(AwsRegion).to receive(:for_state).with(country: 'US', state: 'CA').and_return('invisibru-region')
      end

      it 'should return nil' do
        expect(Region.recommended_for(country: 'US', state: 'CA')).to be_nil
      end
    end

    context 'when there is a recommended region but it is disabled' do
      let!(:ap_southeast_1) { create :region, name: 'ap-southeast-1', enabled: false }

      before do
        expect(AwsRegion).to receive(:for_continent).with('AS').and_return('ap-southeast-1')
      end

      it 'should return nil' do
        expect(Region.recommended_for(continent: 'AS')).to be_nil
      end
    end

    context 'when there is a recommended region but it is down' do
      let!(:ap_southeast_1) { create :region, name: 'ap-southeast-1', enabled: true }

      before do
        expect(AwsRegion).to receive(:for_continent).with('AS').and_return('ap-southeast-1')
        ap_southeast_1.update_attribute('state', 'down')
      end

      it 'should return nil' do
        expect(Region.recommended_for(continent: 'AS')).to be_nil
      end
    end

    context 'when no options are passed' do
      it 'should return nil' do
        expect(Region.recommended_for).to be_nil
      end
    end
  end
end
