require 'spec_helper'

describe Admin::UsersController do
  let!(:user)  { create :user }
  let!(:admin) { create :admin }

  describe '#switch_user' do
    before { sign_in admin }

    def do_request(params = {})
      post :switch_user, params
    end

    context 'when signed in as admin' do
      context 'when the user we want to switch to is valid' do
        it 'signs in as the specified user' do
          do_request email: user.email
          response.should redirect_to(switch_user_path(scope_identifier: "user_#{user.id}"))
        end
      end

      context 'when the user is invalid' do
        it 'redirects back to index with an error' do
          do_request email: 'whatever@email.com'
          response.should redirect_to(admin_users_path)
          flash[:notice].should be_present
        end
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
  end
end
