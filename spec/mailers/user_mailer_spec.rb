require 'spec_helper'

describe UserMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  it 'sends welcome email after user finished registration' do
    mail = UserMailer.welcome "naive@user.io"
    mail.should deliver_to("naive@user.io")
    mail.should deliver_from("Action.IO Team <hello@action.io>")
    mail.should have_subject("Getting Started on Action.IO")
  end
end
