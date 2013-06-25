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
end
