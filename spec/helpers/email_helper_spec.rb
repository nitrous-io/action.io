require 'spec_helper'

describe EmailHelper do
  describe '.mixpanel_pixel_track' do
    let(:mixpanel_tracker) { instance_double 'Mixpanel::Tracker' }

    before do
      Mixpanel::Tracker.stub(:new) { mixpanel_tracker }
    end

    context 'only email, no other extra properties provided' do
      it 'calls Mixpanel::Tracker#tracking_pixel with event, distinct_id and email set' do
        expect(mixpanel_tracker).to receive(:tracking_pixel).with('Some Event', distinct_id: 'user@example.com', email: 'user@example.com')
        mixpanel_pixel_track 'Some Event', 'user@example.com'
      end
    end

    context 'email and extra properties provided' do
      it 'calls Mixpanel::Tracker#tracking_pixel with event, distinct_id and email set' do
        expect(mixpanel_tracker).to receive(:tracking_pixel).with('Some Event', distinct_id: 'user@example.com', email: 'user@example.com', foo: 'bar')
        mixpanel_pixel_track 'Some Event', 'user@example.com', foo: 'bar'
      end
    end
  end
end
