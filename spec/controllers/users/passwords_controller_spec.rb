require 'spec_helper'

describe Users::PasswordsController do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  it 'is a subclass of Devise::PasswordsController' do
    expect(Devise::PasswordsController.subclasses).to include Users::PasswordsController
  end

  describe '#create' do
    let!(:user) { create :user }

    context 'when a request with Content-Type JSON is received' do
      it 'handles the request and respond with no content' do
        post :create, user: { email: user.email }, format: 'json'
        expect(controller).to respond_with :created
      end
    end
  end

  describe '#edit' do
    let!(:user) { create :user }

    context 'when signed in' do
      before do
        sign_in user
        user.send_reset_password_instructions
        get :edit, reset_password_token: 'securetoken'
      end

      it { should render_template :edit }
      it { should respond_with :success }
    end
  end

  describe '#update' do
    let!(:user) { create :user }

    context 'a signed in user' do
      before do
        sign_in user
        user.send_reset_password_instructions
      end

      context 'successfully resets the password' do
        before do
          User.should_receive(:find_or_initialize_with_error_by).and_return(user)
          put :update, user: { reset_password_token: 'securetoken', password: 'password123', password_confirmation: 'password123' }
        end

        it 'should redirect the user to the web app' do
          response.should redirect_to web_app_path
        end

        it 'keeps the user signed in' do
          expect(signed_in?(user)).to eq true
        end
      end

      context 'fails to reset the password' do
        before do
          put :update, user: { reset_password_token: 'badtoken', password: 'password123', password_confirmation: '' }
        end

        it 'should render edit template' do
          expect(response).to render_template(:edit)
        end
      end
    end

    context 'signed out user' do
      before do
        sign_out user
        user.send_reset_password_instructions
      end

      context 'successfully resets the password' do
        before do
          User.should_receive(:find_or_initialize_with_error_by).and_return(user)
          put :update, user: { reset_password_token: 'securetoken', password: 'password123', password_confirmation: 'password123' }
        end

        it 'should redirect the user to the web app' do
          response.should redirect_to web_app_path
        end

        it 'signs in the user' do
          expect(signed_in?(user)).to eq true
        end
      end

      context 'fails to reset the password' do
        before do
          put :update, user: { reset_password_token: 'badtoken', password: 'password123', password_confirmation: '' }
        end

        it 'should render edit template' do
          expect(response).to render_template(:edit)
        end
      end
    end

    context 'a banned user' do
      before do
        sign_out user
        user.ban!
        user.send_reset_password_instructions
      end

      context 'attempting to reset password' do
        before do
          User.should_receive(:find_or_initialize_with_error_by).and_return(user)
          put :update, user: { reset_password_token: 'securetoken', password: 'password123', password_confirmation: 'password123' }
        end

        it 'will fail' do
          expect(response).to render_template(:edit)
        end

        it 'does not sign in user' do
          expect(signed_in?(user)).to eq false
        end
      end
    end
  end
end
