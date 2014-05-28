require 'spec_helper'

describe Hostbuilder do
  describe '.by_name' do
    class Hostbuilder::FooBar; end

    context 'when looking up a Hostbuilder that exists' do
      it 'returns the class in the Hostbuilder namespace' do
        expect(Hostbuilder.by_name('foo_bar')).to eq Hostbuilder::FooBar
      end
    end

    context 'when looking up a class that does not exist' do
      it 'returns nil when it can' do
        expect(Hostbuilder.by_name('does_not_exist')).to be_nil
      end
    end
  end
end
