require 'spec_helper'

describe FetchClosestRegionJob do
  describe '#perform' do
    let!(:region1) { create :region, enabled: true }
    let(:channel) { double.as_null_object }

    it 'should query the Geocoder with the IP address' do
      allow(Geocoder).to receive(:search) # Essentially a test spy.

      FetchClosestRegionJob.new('1.2.3.4', 69).perform

      expect(Geocoder).to have_received(:search).with('1.2.3.4')
    end

    context 'when the Geocoder cannot find a location' do
      before do
        expect(Geocoder).to receive(:search) { nil }
      end

      def do_action
        FetchClosestRegionJob.new('1.2.3.4', 69).perform
      end

      it 'should not lookup the recommended Region' do
        expect(Region).to_not receive(:recommended_for)
        do_action
      end

      it 'should not send a message via Pusher' do
        expect(Pusher).to_not receive(:[])
        expect(Shover).not_to receive(:publish)
        do_action
      end
    end

    context 'when there is no recommended Region' do
      before do
        user_location = double(continent_code: 'AS', country_code: 'SG', state_code: nil)
        expect(Geocoder).to receive(:search).with('6.9.6.9') { user_location }
        expect(Region).to receive(:recommended_for) { nil }
      end

      it 'should not send a message via Pusher' do
        expect(Shover).not_to receive(:publish)
        expect(Pusher).to_not receive(:[])
        FetchClosestRegionJob.new('6.9.6.9', 69).perform
      end
    end

    context 'when there is a recommended Region' do
      before do
        user_location = double(continent_code: 'AS', country_code: 'SG', state_code: nil)
        expect(Geocoder).to receive(:search).with('42.42.42.42') { user_location }
        expect(Region).to receive(:recommended_for) { region1 }
      end

      it "sends a message via Pusher with the region info to the user's channel" do
        expect(Shover).to receive(:publish).with(69, 'aio:fetch_closest_region', region1.serialize_as_hash)
        expect(Pusher).to receive(:[]).with('private-user-69') { channel }
        expect(channel).to receive(:trigger) do |message, region|
          message.should == 'aio:fetch_closest_region'
          region.should == region1.to_json
        end

        FetchClosestRegionJob.new('42.42.42.42', 69).perform
      end
    end
  end
end
