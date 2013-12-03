require 'spec_helper'

describe Api::V0::AuthTokenController do
  it 'is a subclass of AuthTokenController' do
    expect(described_class.superclass).to equal AuthTokenController
  end

  let(:user) { create :user }

  describe 'GET issue' do
    before { stub_action :issue }
    after  { restore_action :issue }

    def do_request
      get :issue, format: 'json', name: 'rainbow'
    end

    it_behaves_like 'an action that requires access token'
    it_behaves_like 'an action that requires access token with scope', :push
  end
end
