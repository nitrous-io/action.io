require 'spec_helper'

describe ApplicationController do
  controller do
    def index
      render nothing: true
    end
  end

  describe '#oauth_token_present?' do
    context 'when access_token param is present' do
      before { get :index, access_token: 'some_token' }

      it 'returns true' do
        expect(controller.send :oauth_token_present?).to be_true
      end
    end

    context 'when bearer_token param is present' do
      before { get :index, bearer_token: 'some_token' }

      it 'returns true' do
        expect(controller.send :oauth_token_present?).to be_true
      end
    end

    context 'when authorization header with content "Bearer <token>" is present' do
      before do
        request.env['HTTP_AUTHORIZATION'] = 'Bearer SomeOAuthToken'
        get :index
      end

      it 'returns true' do
        expect(controller.send :oauth_token_present?).to be_true
      end
    end

    context 'else' do
      before { get :index }

      it 'returns false' do
        expect(controller.send :oauth_token_present?).to be_false
      end
    end
  end
end
