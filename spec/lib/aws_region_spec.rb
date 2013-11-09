require 'spec_helper'

describe AwsRegion do

  describe '.for_continent' do
    before do
      stub_const('AwsRegion::CONTINENT_MAPPING', { 'NA' => 'us-east-1' })
    end

    it 'should return the corresponding value from the CONTINENT_MAPPING hash' do
      AwsRegion.for_continent('NA').should == 'us-east-1'
    end

    it 'should return nil when the continent is not a key in the CONTINENT_MAPPING hash' do
      AwsRegion.for_continent('FU').should be_nil
    end
  end

  describe '.for_country' do
    before do
      stub_const('AwsRegion::COUNTRY_MAPPING', { 'SG' => 'ap-southeast-1' })
    end

    it 'should return the corresponding value from the COUNTRY_MAPPING hash' do
      AwsRegion.for_country('SG').should == 'ap-southeast-1'
    end

    it 'should return nil when the country is not a key in the COUNTRY_MAPPING hash' do
      AwsRegion.for_country('FU').should be_nil
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
      AwsRegion.for_state(country: 'US', state: 'CA').should == 'us-west-1'
      AwsRegion.for_state(country: 'US', state: 'DC').should == 'us-east-1'
    end

    it 'should return nil when the country is not a key in the STATE_MAPPING hash' do
      AwsRegion.for_state(country: 'SG', state: 'SG').should be_nil
    end

    it 'should return nil when the country is a key in the STATE_MAPPING hash but the state is not present' do
      AwsRegion.for_state(country: 'US', state: 'XX').should be_nil
    end
  end

end
