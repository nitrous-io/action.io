require 'spec_helper'

describe PublicKeyMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  it 'sends notification email after user saves a new key' do
    mail = PublicKeyMailer.save_key "naive@user.io", "keyname", "12:23:34"
    mail.should deliver_to("naive@user.io")
    mail.should deliver_from("Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>")
    mail.should have_subject("Nitrous.IO - New public key added to your account")
    mail.should have_body_text("keyname")
    mail.should have_body_text("12:23:34")
  end
end
