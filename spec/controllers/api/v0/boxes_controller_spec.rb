require 'spec_helper'

describe Api::V0::BoxesController do
  it 'is a subclass of BoxesController' do
    expect(described_class.superclass).to equal BoxesController
  end

  let(:user) { create :user }
  before do
    Box.any_instance.stub(:coach) { NullCoach.new(mock_model(Box).as_null_object) }
  end

  describe 'GET index' do
    before { stub_action :index }
    after  { restore_action :index }

    def do_request
      get :index, format: 'json'
    end

    it_behaves_like 'an action that requires access token'
    it_behaves_like 'an action that requires access token with scope', :boxes
  end

  describe 'GET show' do
    before { stub_action :show }
    after  { restore_action :show }

    let!(:box) { create :box, users: [user] }

    def do_request
      get :show, format: 'json', id: box.to_param
    end

    it_behaves_like 'an action that requires access token'
    it_behaves_like 'an action that requires access token with scope', :boxes
  end

  describe 'POST create' do
    before { stub_action :create }
    after  { restore_action :create }

    def do_request
      post :create, format: 'json'
    end

    it_behaves_like 'an action that requires access token'
    it_behaves_like 'an action that requires access token with scope', :boxes
  end

  describe 'PUT start' do
    before { stub_action :start }
    after  { restore_action :start }

    let!(:box) { create :box, users: [user] }

    def do_request
      put :start, format: 'json', id: box.to_param
    end

    it_behaves_like 'an action that requires access token'
    it_behaves_like 'an action that requires access token with scope', :boxes
  end

  describe 'PUT stop' do
    before { stub_action :stop }
    after  { restore_action :stop }

    let!(:box) { create :box, users: [user] }

    def do_request
      put :stop, format: 'json', id: box.to_param
    end

    it_behaves_like 'an action that requires access token'
    it_behaves_like 'an action that requires access token with scope', :boxes
  end

  describe 'PUT restart' do
    before { stub_action :restart }
    after  { restore_action :restart }

    let!(:box) { create :box, users: [user] }

    def do_request
      put :restart, format: 'json', id: box.to_param
    end

    it_behaves_like 'an action that requires access token'
    it_behaves_like 'an action that requires access token with scope', :boxes
  end

  describe 'DELETE destroy' do
    before { stub_action :destroy }
    after  { restore_action :destroy }

    let!(:box) { create :box, users: [user] }

    def do_request
      delete :destroy, format: 'json', id: box.to_param
    end

    it_behaves_like 'an action that requires access token'
    it_behaves_like 'an action that requires access token with scope', :boxes
  end
end
