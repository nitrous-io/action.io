class ReceiptMailer < ActionMailer::Base
  layout 'email'
  helper 'email'
  helper 'receipt'
  default from: "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"

  def send_receipt(receipt_id)
    @receipt = Receipt.find receipt_id
    @billing_profile = @receipt.billing_profile

    mail(subject: "Nitrous.IO Receipt",
         to: @billing_profile.user.email)
  end
end
