require 'spec_helper'

describe Receipt do
  it { should allow_mass_assignment_of :period_start }
  it { should allow_mass_assignment_of :period_end }
  it { should allow_mass_assignment_of :lines }
  it { should allow_mass_assignment_of :subtotal }
  it { should allow_mass_assignment_of :total }

  it { should belong_to(:billing_profile) }

  describe 'period_start setter' do
    let!(:receipt) { build :receipt }

    context 'when the value is an Unix timestamp' do
      it 'converts it to time and assigns it' do
        period_start_date = Time.new(2013, 10, 1)
        receipt.period_start = period_start_date.to_i

        expect(receipt.period_start).to eq(period_start_date)
      end
    end
  end

  describe 'period_end setter' do
    let!(:receipt) { build :receipt }

    context 'when the value is an Unix timestamp' do
      it 'converts it to time and assigns it' do
        period_end_date = Time.new(2013, 10, 31)
        receipt.period_end = period_end_date.to_i

        expect(receipt.period_end).to eq(period_end_date)
      end
    end
  end

  describe "after_create" do
    let!(:receipt) { build :receipt }

    it 'emails the receipt' do
      receipt.save

      ReceiptMailer.should_receive(:send_receipt).with(receipt.id) { stub.as_null_object }
      Delayed::Job.last.invoke_job
    end
  end
end
