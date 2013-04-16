class PublicKeyMailer < ActionMailer::Base
  layout 'email'
  helper 'email'
  default from: 'Nitrous.IO Team <hello@nitrous.io>'

  def save_key(email, name, signature)
    @name = name
    @signature = signature
    headers["X-SMTPAPI"] = JSON.generate(category: 'publickey-create-success')
    mail(subject: "Nitrous.IO - New public key added to your account",
         to:      email)
  end
end
