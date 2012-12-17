require 'spec_helper'

describe Api::V0::PublicKeysController do
  it 'is a subclass of PublicKeysController' do
    expect(described_class.superclass).to equal PublicKeysController
  end

  let(:user) { create :user }

  describe 'GET index' do
    before { stub_action :index }
    after  { restore_action :index }

    def do_request
      get :index, format: 'json'
    end

    it_behaves_like 'an action that requires access token'
    it_behaves_like 'an action that requires access token with scope', :public_keys
  end

  describe 'POST create' do
    before { stub_action :create }
    after  { restore_action :create }

    def do_request
      post :create, format: 'json'
    end

    it_behaves_like 'an action that requires access token'
    it_behaves_like 'an action that requires access token with scope', :public_keys
  end

  describe 'DELETE destroy' do
    before { stub_action :destroy }
    after  { restore_action :destroy }

    let(:public_key) { create :public_key, user: user }

    def do_request
      delete :destroy, format: 'json', id: public_key.id
    end

    it_behaves_like 'an action that requires access token'
    it_behaves_like 'an action that requires access token with scope', :public_keys
  end
end
