class AccountMailer < Devise::Mailer
  layout 'email'
  helper 'email'
  default from: "Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>"

  def confirmation_instructions(record, token, opts={})
    initialize_from_record(record)
    @reconfirmation = @resource.unconfirmed_email.present?

    unless @reconfirmation
      headers = headers_for(:confirmation_instructions, opts).merge(subject: "Confirm your email to start using Nitrous.IO")
    else
      headers = headers_for(:confirmation_instructions, opts).merge(subject: "Confirm your new Nitrous.IO email address")
    end

    mail headers
  end
end
