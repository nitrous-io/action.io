require 'spec_helper'

describe Serializers::JSONSerializer do
  let(:object) { { 'a' => 'foo', 'b' => 'bar' } }

  describe '#dump' do
    it 'encodes object to json' do
      Serializers::JSONSerializer.dump(object).should == '{"a":"foo","b":"bar"}'
    end
  end

  describe '#load' do
    it 'decodes json back to object' do
      Serializers::JSONSerializer.load('{"a":"foo","b":"bar"}').should == object
    end
  end
end
