require 'spec_helper'

describe ReceiptSerializer do
  let!(:receipt) { create :receipt }

  subject { receipt.serialize_as_json }

  it 'has every field' do
    hash = JSON.parse(subject)['receipt']
    expect(hash.delete 'id').to eq receipt.id
    expect(hash.delete 'period_start').to eq receipt.period_start
    expect(hash.delete 'period_end').to eq receipt.period_end
    expect(hash.delete 'lines').to eq receipt.lines
    expect(hash.delete 'subtotal').to eq receipt.subtotal
    expect(hash.delete 'total').to eq receipt.total
    expect(hash).to be_empty
  end
end
