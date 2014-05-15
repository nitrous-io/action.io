require 'spec_helper'

describe ReceiptHelper do
  describe '.as_currency' do
    it 'formats cents to 2 decimal places' do
      expect(as_currency(999)).to eq '$9.99'
      expect(as_currency(1999)).to eq '$19.99'
      expect(as_currency(99)).to eq '$0.99'
    end
  end

  describe '.line_description' do
    context 'when the line has a description' do
      it 'returns the description' do
        line = { "description" => "given description" }
        expect(line_description line).to eq "given description"
      end
    end

    context 'when the line doesnt have a description, but a plan is given' do
      it "returns the description as 'Subscription to #plan'" do
        line = { "plan" => { "name" => "Shift" } }
        expect(line_description line).to eq "Subscription to Shift"
      end
    end
  end
end
