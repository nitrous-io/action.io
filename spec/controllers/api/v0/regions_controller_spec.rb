require 'spec_helper'

describe Api::V0::RegionsController do
  it 'is a subclass of RegionsController' do
    expect(described_class.superclass).to equal RegionsController
  end

  let(:user) { create :user }

  describe 'GET index' do
    before { stub_action :index }
    after  { restore_action :index }

    def do_request
      get :index, format: 'json'
    end

    it_behaves_like 'an action that requires access token'
    it_behaves_like 'an action that requires access token with scope', :boxes
  end
end
