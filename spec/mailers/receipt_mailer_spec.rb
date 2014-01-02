require 'spec_helper'

describe ReceiptMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  describe 'send_receipt' do
    let!(:receipt)    { create :receipt, period_start: Time.new(2013, 12, 16).to_i, period_end: Time.new(2014, 1, 16).to_i }

    context 'when receipt contains a plan name' do
      before do
        receipt.lines = [{
          'amount' => 500,
          'currency' => 'usd',
          'quantity' => 1,
          'description' => nil,
          'period' => {
            'start' => Time.new(2013, 12, 16).to_i,
            'end' =>  Time.new(2014, 1, 16).to_i
          },
          'plan' => {
            'name' => '500 N2O'
          }
        }]

        receipt.save
      end

      it 'emails the created receipt to the user' do
        user = receipt.billing_profile.user
        mail = ReceiptMailer.send_receipt receipt.id

        expect(mail).to deliver_to user.email
        expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
        expect(mail).to have_subject('Nitrous.IO Receipt')
      end

      it 'includes plan name and amount' do
        mail = ReceiptMailer.send_receipt receipt.id

        expect(mail).to have_body_text("Plan: #{receipt.lines.first['plan']['name']}")
        expect(mail).to have_body_text('Amount: USD5.00')
      end
    end

    context 'when receipt does not contain a plan name, but has a description' do
      before do
        receipt.lines = [{
          'amount' => 500,
          'currency' => 'usd',
          'quantity' => 1,
          'description' => 'Details of the purchase',
          'period' => {
            'start' => Time.new(2013, 12, 16).to_i,
            'end' =>  Time.new(2014, 1, 16).to_i
          },
          'plan' => nil
        }]

        receipt.save
      end

      it 'emails the created receipt to the user' do
        user = receipt.billing_profile.user
        mail = ReceiptMailer.send_receipt receipt.id

        expect(mail).to deliver_to user.email
        expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
        expect(mail).to have_subject('Nitrous.IO Receipt')
      end

      it "includes description and amount" do
        mail = ReceiptMailer.send_receipt receipt.id

        expect(mail).to have_body_text('Details of the purchase')
        expect(mail).to have_body_text('Amount: USD5.00')
      end
    end

  end
end
