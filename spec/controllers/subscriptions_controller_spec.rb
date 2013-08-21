require 'spec_helper'

describe SubscriptionsController do
  let(:user) { create :user }

  describe 'POST create' do
    def do_request(params={ subscription: {} })
      post :create, { format: 'json'}.merge(params)
    end

    context 'when signed in' do
      before do
        sign_in user
      end

      context 'with valid params' do

      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
