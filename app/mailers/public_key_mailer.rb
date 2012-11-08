class PublicKeyMailer < ActionMailer::Base
  layout 'email'
  helper 'email'
  default from: 'Action.IO Team <hello@action.io>'

  def save_key(email, name, signature)
    @name = name
    @signature = signature
    headers["X-SMTPAPI"] = JSON.generate(category: 'publickey-create-success')
    mail(subject: "ActionIO - New public key added to your account",
         to:      email)
  end
end
