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
    let(:user)          { create :user }
    let!(:another_user) { create :user }

    let!(:box)  { create :box, owner: user, users: [user] }
    let!(:box2) { create :box, owner: user, users: [user] }
    let!(:box3) { create :box, owner: another_user, users: [another_user, user] }
    let!(:box4) { create :box, owner: user, users: [user] }

    def do_request
      get :index, format: 'json'
    end

    context 'with access token' do
      before do
        controller.stub(:doorkeeper_token) { double accessible?: true, resource_owner_id: user.id, scopes: Doorkeeper::OAuth::Scopes.from_string('boxes') }
        Timecop.freeze do
          box4.update_attribute :terminated_at, 1.day.ago
          do_request
        end
      end

      it { should respond_with :success }

      it "returns the current user's boxes as json" do
        response.body.should eq({ boxes: [box, box2].serialize_as_hash }.to_json)
      end
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

    let!(:box) { create :box, owner: user }

    def do_request
      put :start, format: 'json', id: box.to_param
    end

    it_behaves_like 'an action that requires access token'
    it_behaves_like 'an action that requires access token with scope', :boxes
  end

  describe 'PUT stop' do
    before { stub_action :stop }
    after  { restore_action :stop }

    let!(:box) { create :box, owner: user }

    def do_request
      put :stop, format: 'json', id: box.to_param
    end

    it_behaves_like 'an action that requires access token'
    it_behaves_like 'an action that requires access token with scope', :boxes
  end

  describe 'PUT restart' do
    before { stub_action :restart }
    after  { restore_action :restart }

    let!(:box) { create :box, owner: user }

    def do_request
      put :restart, format: 'json', id: box.to_param
    end

    it_behaves_like 'an action that requires access token'
    it_behaves_like 'an action that requires access token with scope', :boxes
  end

  describe 'DELETE destroy' do
    before { stub_action :destroy }
    after  { restore_action :destroy }

    let!(:box) { create :box, owner: user }

    def do_request
      delete :destroy, format: 'json', id: box.to_param
    end

    it_behaves_like 'an action that requires access token'
    it_behaves_like 'an action that requires access token with scope', :boxes
  end
end
