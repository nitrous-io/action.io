require 'spec_helper'

describe UsersController do
  let(:user) { create :user }

  describe 'PUT intro_seen' do
    def do_request
      put :intro_seen, format: 'json'
    end

    context 'when signed in' do
      before do
        sign_in user
        do_request
      end

      it 'responds with no content and marks intro_seen to be true' do
        expect(user.intro_seen).to be_false
        do_request
        expect(user.reload.intro_seen).to be_true
        expect(controller).to respond_with :no_content
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'PUT chrome_app_installed' do
    def do_request
      put :chrome_app_installed, format: 'json'
    end

    before do
      create :key_value, key: N2oFill::N2O_INSTALL_CHROME_APP_BONUS, value: 10
    end

    context 'when signed in' do
      before do
        sign_in user
        controller.stub(:current_user) { user }
      end

      it 'responds with no content and calls fill_n2o_for_chrome_app_installation! on user' do
        user.should_receive :fill_n2o_for_chrome_app_installation!
        do_request
        expect(controller).to respond_with :no_content
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
