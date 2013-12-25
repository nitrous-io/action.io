class ReceiptMailer < ActionMailer::Base
  layout 'email'
  helper 'email'
  helper 'receipt'
  default from: "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"

  def send_receipt(receipt_id)
    @receipt = Receipt.find receipt_id
    @billing_profile = @receipt.billing_profile
    @user = @billing_profile.user

    if @receipt.plan_name
      @description = "Plan: #{@receipt.plan_name}"
    else
      @description = @receipt.first_line_description
    end

    mail(subject: "Nitrous.IO Receipt",
         to: @user.email,
         bcc: %w(billing+success@nitrous.io eng@action.io)
        )
  end
end
