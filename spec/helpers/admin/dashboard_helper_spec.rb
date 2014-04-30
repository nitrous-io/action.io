require 'spec_helper'

describe Admin::DashboardHelper do
  describe '.loss' do
    it 'surrounds given string with parentheses' do
      expect(loss('$9.99')).to eq '( $9.99 )'
      expect(loss('lose already')).to eq '( lose already )'
    end
  end
end
