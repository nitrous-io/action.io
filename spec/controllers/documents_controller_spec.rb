require 'spec_helper'

describe DocumentsController do
  describe 'GET index' do
    let!(:box) { create :box }

    def do_request(box_id=box.id)
      get :index, box_id: box_id, format: :json
    end

    context 'when signed in' do
      let(:user) { box.owner }
      let!(:documents) { [create(:document, user: user, box: box)] }

      before { sign_in user }

      it 'returns a list of documents' do
        do_request
        assigns(:documents).should eq(documents)
        response.body.should eq({documents: documents.serialize_as_hash}.to_json)
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
