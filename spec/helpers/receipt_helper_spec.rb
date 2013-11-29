require 'spec_helper'

describe ReceiptHelper do
  describe '.as_currency' do
    it 'formats cents to 2 decimal places' do
      expect(as_currency(999)).to eq 'USD9.99'
      expect(as_currency(1999)).to eq 'USD19.99'
      expect(as_currency(99)).to eq 'USD0.99'
    end
  end
end
