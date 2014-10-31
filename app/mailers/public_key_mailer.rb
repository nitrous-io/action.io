class PublicKeyMailer < ActionMailer::Base
  layout 'email'
  helper 'email'
  default from: "Nitrous <support@#{ENV['RAILS_DOMAIN']}>"

  def save_key(email, name, signature)
    @name = name
    @signature = signature
    headers["X-SMTPAPI"] = JSON.generate(category: 'publickey-create-success')
    mail(subject: "Nitrous - New public key added to your account",
         to:      email)
  end
end
