require 'spec_helper'

describe Api::V0::MiscController do
  let(:user) { create :user }

  describe 'GET scopes' do
    def do_request
      get :scopes
    end

    it "returns the access token's scopes" do
      controller.stub(:doorkeeper_token) { double accessible?: true, resource_owner_id: user.id, scopes: :'foo bar' }
      do_request
      expect(controller).to respond_with :success
      expect(response.body).to eq({ scopes: 'foo bar' }.to_json)
    end

    it_behaves_like 'an action that requires access token'
  end
end
