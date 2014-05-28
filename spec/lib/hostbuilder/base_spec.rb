require 'spec_helper'

describe Hostbuilder::Base do
  describe 'constructor' do
    it 'assigns its first argument to @boxhost' do
      hostbuilder = Hostbuilder::Base.new('first-arg')
      expect(hostbuilder.boxhost).to eq 'first-arg'
    end
  end
end
