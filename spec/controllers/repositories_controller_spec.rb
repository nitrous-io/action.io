require 'spec_helper'

describe RepositoriesController do
  let(:user) { create :user }

  describe 'GET index' do
    let!(:box) { create :box, owner: user }
    let!(:another_user) { create :user }
    let!(:another_box) { create :box, owner: another_user }
    let!(:repository1) { create :repository, box: box }
    let!(:repository2) { create :repository, box: box }
    let!(:repository3) { create :repository, box: another_box }

    def do_request
      get :index, format: 'json'
    end

    context 'when signed in' do
      before do
        sign_in user
        do_request
      end

      it { should respond_with :success }

      it "returns the current user's repositories as json" do
        expect(assigns(:repositories)).to match_array([repository1, repository2])
        expect(response.body).to eq({ repositories: assigns(:repositories).serialize_as_hash }.to_json)
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'GET clone' do
    context 'when signed in' do
      before { sign_in user }

      it "sets the user's intent" do
        get :clone, url: 'https://github.com/rails/rails.git'
        expect(user.reload.intent[:kind]).to eql 'clone_repo'
        expect(user.reload.intent[:data][:url]).to eql 'https://github.com/rails/rails.git'
      end

      context 'when user has visible boxes' do
        let!(:box) { create :box, owner: user }

        it 'redirects to the box picker page' do
          get :clone, url: 'https://github.com/rails/rails.git'
          expect(response).to redirect_to('/app#/boxes/clone_repo_picker')
        end
      end

      context 'when user has no visible boxes' do
        it 'redirects to the new box page' do
          get :clone, url: 'https://github.com/rails/rails.git'
          expect(response).to redirect_to('/app#/intro/create')
        end
      end
    end

    context 'when not signed in' do
      before do
        get :clone, url: 'https://github.com/rails/rails.git'
      end

      it 'assigns the url param to @url' do
        expect(assigns(:url)).to eql 'https://github.com/rails/rails.git'
      end

      it 'assigns the sign up path with the intent encoded as a querystring to @sign_up_path' do
        path = assigns(:sign_up_path)
        expect(path).to match %r[#{new_user_registration_path}]
        encoded_intent = {
          kind: 'clone_repo',
          data: { url: 'https://github.com/rails/rails.git' }
        }.to_query
        query = {
          intent: encoded_intent
        }
        expect(path).to match %r[#{query.to_param}]
      end

      it 'assigns the sign in path to @sign_in_path with a redirect back to itself' do
        path = assigns(:sign_in_path)
        expect(path).to match %r[#{new_user_session_path}]
        query = {
          redirect_to: clone_repository_path(url: 'https://github.com/rails/rails.git')
        }
        expect(path).to match %r[#{query.to_param}]
      end

      it { should respond_with :success }
      it { should render_template :clone }
    end
  end
end
