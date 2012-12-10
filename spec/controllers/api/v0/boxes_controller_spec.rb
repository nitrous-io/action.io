require 'spec_helper'

describe Api::V0::BoxesController do
  before { Box.any_instance.stub :push_box_added_message }

  it 'is a subclass of BoxesController' do
    expect(described_class.superclass).to equal BoxesController
  end

  let(:user) { create :user }

  def stub_action(action)
    described_class.class_eval do
      alias_method :"orig_#{action}", action.to_sym
      define_method action.to_sym do
        render nothing: true
      end
    end
  end

  def restore_action(action)
    described_class.class_eval do
      alias_method action.to_sym, :"orig_#{action}"
    end
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
end
