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
    def do_request(params={})
      post :identify_scm, params.merge(format: 'json')
    end

    context 'when signed in' do
      before do
        sign_in user
      end

      it 'returns 200 on success' do
        IdentifyRepositoryJob.should_receive(:submit_job)
        do_request
        expect(controller).to respond_with :success
      end

      it 'renders 422 on error' do
        IdentifyRepositoryJob.should_receive(:submit_job).and_raise(StandardError, "broken")
        Rails.logger.should_receive(:error).with(/Error in IdentifyRepositoryJob/)
        do_request
        expect(controller).to respond_with :unprocessable_entity
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
