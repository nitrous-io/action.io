require 'spec_helper'

describe UserMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  it 'sends welcome email after user finished registration' do
    mail = UserMailer.welcome "naive@user.io"
    mail.should deliver_to("naive@user.io")
    mail.should deliver_from("Nitrous.IO <support@#{ENV['RAILS_DOMAIN']}>")
    mail.should have_subject("Getting Started on Nitrous.IO")
  end
end
