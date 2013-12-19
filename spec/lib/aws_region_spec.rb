require 'spec_helper'

describe AwsRegion do

  describe '.for_continent' do
    before do
      stub_const('AwsRegion::CONTINENT_MAPPING', { 'NA' => 'us-east-1' })
    end

    it 'should return the corresponding value from the CONTINENT_MAPPING hash' do
      expect(AwsRegion.for_continent('NA')).to eq('us-east-1')
    end

    it 'should return nil when the continent is not a key in the CONTINENT_MAPPING hash' do
      expect(AwsRegion.for_continent('FU')).to be_nil
    end
  end

  describe '.for_country' do
    before do
      stub_const('AwsRegion::COUNTRY_MAPPING', { 'SG' => 'ap-southeast-1' })
    end

    it 'should return the corresponding value from the COUNTRY_MAPPING hash' do
      expect(AwsRegion.for_country('SG')).to eq('ap-southeast-1')
    end

    it 'should return nil when the country is not a key in the COUNTRY_MAPPING hash' do
      expect(AwsRegion.for_country('FU')).to be_nil
    end
  end

  describe '.for_state' do
    before do
      stub_const('AwsRegion::COUNTRY_MAPPING', {
        'US' => { 'CA' => 'us-west-1' },
        'US' => { 'DC' => 'us-east-1' }
      })
    end

    it 'should return the corresponding value from the STATE_MAPPING hash' do
      expect(AwsRegion.for_state(country: 'US', state: 'CA')).to eq('us-west-1')
      expect(AwsRegion.for_state(country: 'US', state: 'DC')).to eq('us-east-1')
    end

    it 'should return nil when the country is not a key in the STATE_MAPPING hash' do
      expect(AwsRegion.for_state(country: 'SG', state: 'SG')).to be_nil
    end

    it 'should return nil when the country is a key in the STATE_MAPPING hash but the state is not present' do
      expect(AwsRegion.for_state(country: 'US', state: 'XX')).to be_nil
    end
  end

end
