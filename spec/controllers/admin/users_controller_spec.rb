require 'spec_helper'

describe Admin::UsersController do
  let!(:user)  { create :user }
  let!(:admin) { create :admin }
  let!(:box) { create :box, owner: user }

  describe '#switch_user' do
    before { sign_in admin }

    def do_request(params = {})
      post :switch_user, params
    end

    context 'when signed in as admin' do
      context 'when we provide a valid email' do
        it 'signs in as the specified user' do
          do_request identifier: user.email
          response.should redirect_to(switch_user_path(scope_identifier: "user_#{user.id}"))
        end
      end

      context 'when we provide a valid username' do
        it 'signs in as the specified user' do
          do_request identifier: user.username
          response.should redirect_to(switch_user_path(scope_identifier: "user_#{user.id}"))
        end
      end

      context 'when we provide a valid box id' do
        it 'signs in as owner of the specified box' do
          do_request identifier: box.id
          response.should redirect_to(switch_user_path(scope_identifier: "user_#{user.id}"))
        end
      end

      context 'when the user is invalid' do
        it 'redirects back to index with an error' do
          do_request identifier: 'whatever@email.com'
          response.should redirect_to(admin_users_path)
          flash[:notice].should be_present
        end
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
  end
end
