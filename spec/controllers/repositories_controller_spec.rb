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

  describe 'POST identify_scm' do
    let!(:box) { create :box }

    def do_request(repository_params={})
      post :identify_scm, { format: 'json', repository: { box_id: box.to_param, clone_url: 'https://github.com/nitrous-io/autoparts'}.merge(repository_params) }
    end

    context 'when signed in' do
      before { sign_in box.owner }

      context 'when box_id is present' do
        context 'when a repository clone URL is given' do
          it 'creates a new repository' do
            expect(IdentifyRepositoryJob).to receive(:submit_job)
            expect {
              do_request
            }.to change { box.repositories.count }.by(1)
            repo = box.repositories.last
            expect(repo.state).to eq 'identifying'
          end
        end

        context 'when a repository clone URL is not given' do
          it 'does not create a new repository' do
            expect {
              do_request(clone_url: '')
            }.to_not change { box.repositories.count }
            expect(controller).to respond_with :unprocessable_entity
            expect(JSON.parse(response.body)['errors']['base']).to eq ['No url to clone']
          end
        end
      end

      context 'when box_id is absent' do
        context 'when a repository clone URL params exists' do
          it 'does not create a new repository' do
            expect(IdentifyRepositoryJob).to receive(:submit_job)
            expect {
              do_request(box_id: nil)
            }.to_not change { box.repositories.count }.by(1)
          end
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
    it_behaves_like 'an action that returns 403 when user is delinquent'
  end
end
