require 'spec_helper'

describe ReceiptMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  describe "send_receipt" do
    let!(:receipt)    { create :receipt }

    it "emails the created receipt to the user" do
      user = receipt.billing_profile.user
      mail = ReceiptMailer.send_receipt receipt.id

      expect(mail).to deliver_to user.email
      expect(mail).to deliver_from "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"
      expect(mail).to have_subject("Nitrous.IO Receipt")
    end

    it "includes billing period, line items, total and subtotal" do
      mail = ReceiptMailer.send_receipt receipt.id

      expect(mail).to have_body_text("Plan name: #{receipt.lines[0]["name"]}")
      expect(mail).to have_body_text("Charge: USD5.00")
      expect(mail).to have_body_text("Subtotal: USD5.00")
      expect(mail).to have_body_text("Total: USD5.00")
    end
  end
end
