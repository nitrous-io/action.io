require 'spec_helper'

describe RegionsController do
  describe 'GET index' do
    let!(:region1) { create :region, enabled: true }
    let!(:region2) { create :region, enabled: true }
    let!(:region3) { create :region }

    before { get :index, format: 'json' }

    it { should respond_with :success }

    it "returns the list of regions in json" do
      expect(assigns(:regions)).to eq([region1, region2])
      expect(response.body).to eq({ regions: assigns(:regions).serialize_as_hash }.to_json)
    end
  end

  describe 'GET closest' do
    let!(:region1) { create :region, enabled: true }

    def do_request
      get :closest, format: 'json'
    end

    context 'when the user IP address is present in the request' do
      before do
        expect(request).to receive(:remote_ip) { '1.2.3.4' }
      end

      it 'should ask the Geocoder for the user IP address' do
        allow(Geocoder).to receive(:search) # Essentially a test spy.
        do_request

        expect(Geocoder).to have_received(:search).with('1.2.3.4')
      end
    end

    context 'when the user IP address is not available' do
      before do
        expect(request).to receive(:remote_ip) { nil }
        do_request
      end

      it { should respond_with :not_found }
      its('response.body') { should == { error: 'invalid ip' }.to_json }

      it 'should not ask the Geocoder' do
        expect(Geocoder).to_not receive(:search)
      end
    end

    context 'when there is a recommended Region' do
      before do
        expect(request).to receive(:remote_ip) { '42.42.42.42' }
        user_location = double(continent_code: 'AS', country_code: 'SG', state_code: nil)
        expect(Geocoder).to receive(:search).with('42.42.42.42') { user_location }
        expect(Region).to receive(:recommended_for) { region1 }

        do_request
      end

      it { should respond_with :success }

      it 'returns the region in json' do
        expect(assigns(:region)).to eq(region1)
        expect(response.body).to eq(assigns(:region).serialize_as_hash.to_json)
      end
    end

    context 'when there is no recommended Region' do
      before do
        expect(request).to receive(:remote_ip) { '6.9.6.9' }
        user_location = double(continent_code: 'AS', country_code: 'SG', state_code: nil)
        expect(Geocoder).to receive(:search).with('6.9.6.9') { user_location }
        expect(Region).to receive(:recommended_for) { nil }

        do_request
      end

      it { should respond_with :not_found }
      its('response.body') { should == { error: 'unknown closest region' }.to_json }
    end
  end

  describe 'GET fetch_closest' do
    let!(:region1) { create :region, enabled: true }
    let!(:user) { create :user, id: 69 }
    let(:job) { double.as_null_object }

    def do_request
      get :fetch_closest, format: 'json'
    end

    context "when signed in" do
      before do
        sign_in user
      end

      context 'when the user IP address is present in the request' do
        before do
          expect(request).to receive(:remote_ip) { '1.2.3.4' }
          expect(FetchClosestRegionJob).to receive(:new).with('1.2.3.4', 69) { job }
          Delayed::Job.stub(:enqueue)
          do_request
        end

        it { should respond_with :success }
        its('response.body') { should == { status: 'ok' }.to_json }

        it 'should enqueue a delayed job to fetch the closest region' do
          expect(Delayed::Job).to have_received(:enqueue).with(job)
        end
      end

      context 'when the user IP address is not available' do
        before do
          expect(request).to receive(:remote_ip) { nil }
          do_request
        end

        it { should respond_with :not_found }
        its('response.body') { should == { error: 'invalid ip' }.to_json }

        it 'should not create a job' do
          expect(FetchClosestRegionJob).to_not receive(:new)
        end
      end
    end


    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
