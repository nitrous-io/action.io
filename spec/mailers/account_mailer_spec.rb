require 'spec_helper'

describe AccountMailer do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  # simple spec to check that Devise 3.1 upgrade populates @token instance var
  describe 'confirmation_instructions' do
    let!(:user) { create :user }

    it 'includes a proper token' do
      mail = AccountMailer.confirmation_instructions user, 'thetoken'
      expect(mail).to have_body_text(user_confirmation_path(confirmation_token: 'thetoken'))
    end
  end

  # simple spec to check that Devise 3.1 upgrade populates @token instance var
  describe 'reset_password_instructions' do
    let!(:user) { create :user }

    it 'includes a proper token' do
      mail = AccountMailer.reset_password_instructions user, 'thetoken'
      expect(mail).to have_body_text(edit_user_password_path(reset_password_token: 'thetoken'))
    end
  end

  describe 'unlock_instructions' do
    it 'needs a better e-mail if Lockable is activated' do
      # if this fails, improve the Devise default app/views/account_mailers/unlock_instructions.html.erb email!
      expect(User.ancestors).not_to include(Devise::Models::Lockable)
    end
  end
end
