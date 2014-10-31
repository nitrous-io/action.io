class AccountMailer < Devise::Mailer
  layout 'email'
  helper 'email'
  default from: "Nitrous <support@#{ENV['RAILS_DOMAIN']}>"

end
