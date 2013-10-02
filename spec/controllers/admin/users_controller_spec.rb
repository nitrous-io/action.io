require 'spec_helper'

describe Admin::UsersController do
  let!(:user)  { create :user }
  let!(:admin) { create :admin }
  let!(:box) { create :box, owner: user }

  describe 'GET index' do
    before { sign_in admin }

    def do_request(params = {})
      get :index, params
    end

    context 'when signed in as admin' do
      context 'when page is requested without any user identifier' do
        before { do_request }
        it { should respond_with :success }
        it { should render_template 'index' }
      end

      context 'when we provide a valid email' do
        it 'assigns the user with the specified email' do
          do_request identifier: user.email
          expect(assigns(:user)).to eq(user)
        end
      end

      context 'when we provide a valid username' do
        it 'assigns the user with the specified username' do
          do_request identifier: user.username
          expect(assigns(:user)).to eq(user)
        end
      end

      context 'when we provide a valid box id' do
        it 'assigns the owner of the specified box as the user' do
          do_request identifier: box.id
          expect(assigns(:user)).to eq(user)
        end
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
  end

  describe 'POST switch' do
    before { sign_in admin }

    def do_request(params = {})
      post :switch, { id: user.to_param }.merge(params)
    end

    context 'when signed in as admin' do
      context 'when a valid user id is provided' do
        it 'signs in as the specified user' do
          do_request
          response.should redirect_to(switch_user_path(scope_identifier: "user_#{user.id}"))
        end
      end

      context 'when the user id is invalid' do
        it 'raises ActiveRecord::RecordNotFound error' do
          expect { do_request id: 9999 }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
  end

  describe 'GET edit' do
    before { sign_in admin }
    let!(:user) { create :user }

    def do_request(params={})
      get :edit, { id: user.to_param }.merge(params)
    end

    context 'when an user with a given id exist' do
      before { do_request }

      it { should respond_with :success }
      it { should render_template :edit }

      it 'assigns the user to @user' do
        expect(assigns(:user)).to eq(user)
      end
    end

    context 'when an user with a given id does not exist' do
      it 'raises ActiveRecord::RecordNotFound error' do
        expect { do_request id: 9001 }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

  describe 'PUT update' do
    before { sign_in admin }
    let!(:user) { create :user }

    def do_request(params={})
      put :update, { id: user.to_param, user: { username: 'modified-username' } }.merge(params)
    end

    context 'with valid params' do
      it 'updates the item' do
        expect {
          do_request
        }.to change { user.reload.username }.to('modified-username')

        expect(response).to redirect_to admin_users_url(params: {identifier: user.email})
      end
    end

    context 'with invalid params' do
      it 'does not update the item' do
        expect {
          do_request id: user.to_param, user: { username: nil }
        }.not_to change { user.reload.username }.to('modified_username')

        expect(response).to redirect_to admin_users_url(params: {identifier: user.email})
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
  end

  describe 'GET fill_n2o' do
    before { sign_in admin }
    let!(:user) { create :user }

    def do_request(params={})
      get :fill_n2o, { id: user.to_param }.merge(params)
    end

    context 'when an user with a given id exist' do
      before { do_request }

      it { should respond_with :success }
      it { should render_template :fill_n2o }

      it 'assigns the user to @user' do
        expect(assigns(:user)).to eq(user)
      end
    end

    context 'when an user with a given id does not exist' do
      it 'raises ActiveRecord::RecordNotFound error' do
        expect { do_request id: 9001 }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

  describe 'PUT commit_fill_n2o' do
    before { sign_in admin }
    let!(:user) { create :user }

    def do_request(params={})
      post :commit_fill_n2o, { id: user.to_param, amount: 100 }.merge(params)
    end

    context 'with valid n2o amount' do
      it 'fills the user account with n2o' do
        expect {
          do_request
        }.to change { user.reload.max_n2o }.by(100)

        expect(response).to redirect_to admin_users_url(params: {identifier: user.email})
      end
    end

    context 'with invalid n2o amount' do
      it 'does not fill n2o to user account' do
        expect {
          do_request id: user.to_param, amount: nil
        }.not_to change { user.reload.max_n2o }

        expect(response).to redirect_to admin_users_url(params: {identifier: user.email})
      end
    end

    it_behaves_like 'an action that returns 403 when not signed in as an admin'
  end
end
