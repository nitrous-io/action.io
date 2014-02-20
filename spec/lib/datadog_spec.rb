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

  describe '.emit' do
    let!(:client) { double :client }

    before do
      expect(Settings).to receive(:rails_host).and_return 'www.nitrous.io'
      expect(Datadog).to receive(:client).and_return client
    end

    it 'should send the method to datadog' do
      expect(client).to receive(:emit).with('event', 42, host: 'www.nitrous.io')
      Datadog.emit('event', 42)
    end
  end
end
