require 'spec_helper'

describe KeyValue do
  it { should allow_mass_assignment_of :key }
  it { should allow_mass_assignment_of :value }
  it { should_not allow_mass_assignment_of :json_value }

  let(:kv) { KeyValue.new }

  describe '#value' do
    it 'parses and returns json_value' do
      kv.json_value = nil
      expect(kv.value).to be_nil
      kv.json_value = ''
      expect(kv.value).to be_nil
      kv.json_value = 'null'
      expect(kv.value).to be_nil
      kv.json_value = '"hello world"'
      expect(kv.value).to eq 'hello world'
      kv.json_value = '123'
      expect(kv.value).to eq 123
      obj = { 'foo' => ['bar', 123] }
      kv.json_value = obj.to_json
      expect(kv.value).to eq obj
      kv.json_value = '[123]'
      expect(kv.value).to eq [123]
    end
  end

  describe '#value=' do
    it 'warps the value in array, encodes as json and assigns json_value' do
      kv.value = nil
      expect(kv.json_value).to be_nil
      kv.value = ''
      expect(kv.json_value).to eq '""'
      kv.value = 'hello world'
      expect(kv.json_value).to eq '"hello world"'
      kv.value = 123
      expect(kv.json_value).to eq '123'
      obj = { foo: ['bar', 123] }
      kv.value = obj
      expect(kv.json_value).to eq obj.to_json
      kv.value = [123]
      expect(kv.json_value).to eq '[123]'
    end

    it 'works as part of constuctor' do
      kv = KeyValue.new key: 'foo', value: ['bar']
      expect(kv.json_value).to eq '["bar"]'
    end
  end
end
