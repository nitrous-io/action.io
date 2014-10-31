require 'spec_helper'

describe PublicKeyMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  it 'sends notification email after user saves a new key' do
    mail = PublicKeyMailer.save_key "naive@user.io", "keyname", "12:23:34"
    expect(mail).to deliver_to("naive@user.io")
    expect(mail).to deliver_from("Nitrous <support@#{ENV['RAILS_DOMAIN']}>")
    expect(mail).to have_subject("Nitrous - New public key added to your account")
    expect(mail).to have_body_text("keyname")
    expect(mail).to have_body_text("12:23:34")
  end
end
