require 'spec_helper'

describe EmberJS do
  describe '.route' do
    context 'when no query parameters are given' do
      it 'returns just the path' do
        route = EmberJS.route('/app#/boxes')
        expect(route).to eql '/app#/boxes'
      end
    end

    context 'when there are query parameters' do
      it 'returns the path with the query parameters added as a query string' do
        route = EmberJS.route('/app#/boxes', name: 'wicked-baby')
        expect(route).to eql '/app#/boxes?name=wicked-baby'

        route = EmberJS.route('/app#/boxes', name: 'vigorous-trucker', runtime: 'rails')
        expect(route).to eql '/app#/boxes?name=vigorous-trucker&runtime=rails'
      end
    end
  end
end
