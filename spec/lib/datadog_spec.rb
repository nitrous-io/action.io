require 'spec_helper'

describe Datadog do
  describe 'client' do
    let!(:client) { double :client }

    before do
      ENV['DATADOG_API_KEY'] = 'datadog-api-key'
    end

    it 'should instantiate a Datadog API Client' do
      expect(Dogapi::Client).to receive(:new).with('datadog-api-key').and_return client
      Datadog.client
    end
  end

  describe '.emit_point' do
    let!(:client) { double :client }

    before do
      expect(Datadog).to receive(:client).and_return client
    end

    context 'when host is provided' do
      it 'should send the method to datadog' do
        expect(client).to receive(:emit_point).with('metric', 42, host: 'www.nitrous.io')
        Datadog.emit_point('metric', 42, host: 'www.nitrous.io')
      end

      it 'should tag the metric for datadog' do
        expect(client).to receive(:emit_point).with('metric', 42, host: 'www.nitrous.io', tags: ['development'])
        Datadog.emit_point('metric', 42, host: 'www.nitrous.io', tags: ['development'])
      end
    end

    context 'when host is not provided' do
      before { expect(Settings).to receive(:rails_host).and_return 'www1.nitrous.io' }

      it 'should send the method to datadog' do
        expect(client).to receive(:emit_point).with('metric', 42, host: 'www1.nitrous.io')
        Datadog.emit_point('metric', 42)
      end

      it 'should tag the metric for datadog' do
        expect(client).to receive(:emit_point).with('metric', 42, host: 'www1.nitrous.io', tags: ['development'])
        Datadog.emit_point('metric', 42, tags: ['development'])
      end
    end
  end
end
