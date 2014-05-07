require 'spec_helper'

describe Geocoder do
  describe ".search" do

    context 'when ip is provided' do

      context 'and response from geocoding service is OK' do
        let(:location) { Geocoder.search('1.2.3.4') }
        let(:parsed_response) { JSON.parse('{"timezone":"Asia\/Singapore","isp":"StarHub Cable Vision Ltd","country":"Singapore","dma_code":"0","region_code":"00","area_code":"0","ip":"202.156.8.226","asn":"AS10091","continent_code":"AS","city":"Singapore","longitude":103.8558,"latitude":1.2931,"country_code":"SG","country_code3":"SGP"}') }

        before do
          expect(HTTParty).to receive(:get).with('http://www.telize.com/geoip/1.2.3.4', hash_including(timeout: anything)) do
            double 'response', code: 200, parsed_response: parsed_response
          end
        end

        it 'should return a Geocoder::Location instance' do
          expect(location).to be_an_instance_of Geocoder::Location
        end

        it 'should return an object with the city from the response' do
          expect(location.city).to eq('Singapore')
        end

        it 'should return an object with the state_code from the region_code in the response' do
          expect(location.state_code).to eq('00')
        end

        it 'should return an object with the country from the response' do
          expect(location.country).to eq('Singapore')
        end

        it 'should return an object with the country_code from the response' do
          expect(location.country_code).to eq('SG')
        end

        it 'should return an object with the continent_code from the response' do
          expect(location.continent_code).to eq('AS')
        end

        it 'should return an object with the latitude from the response' do
          expect(location.latitude).to eq(1.2931)
        end

        it 'should return an object with the longitude from the response' do
          expect(location.longitude).to eq(103.8558)
        end

        it 'should return an object with a data method that equals parsed response' do
          expect(location.data).to eq(parsed_response)
        end
      end

    end

    context 'when the response from the geocoding service is not HTTP 200 OK' do
      before do
        expect(HTTParty).to receive(:get).with('http://www.telize.com/geoip/1.2.3.4', hash_including(timeout: anything)) do
          double 'response', code: 400, parsed_response: ''
        end
      end

      it 'should return nil' do
        expect(Geocoder.search('1.2.3.4')).to be_nil
      end
    end

    context 'when there is a timeout in the geocoding service' do
      before do
        expect(HTTParty).to receive(:get).with('http://www.telize.com/geoip/1.2.3.4', hash_including(timeout: anything)).and_raise Timeout::Error
      end

      it 'should return nil' do
        expect(Geocoder.search('1.2.3.4')).to be_nil
      end
    end

    context 'when ip is not provided' do
      it 'should return nil' do
        expect(Geocoder.search(nil)).to be_nil
      end
    end

  end
end
