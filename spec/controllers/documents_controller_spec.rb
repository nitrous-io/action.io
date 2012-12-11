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

  describe 'POST create' do
    let!(:box) { create :box }

    def do_request(params={})
      post :create, document: params, box_id: box.id, format: :json
    end

    context 'when signed in' do
      let(:user) { box.owner }

      before { sign_in user }

      it 'creates and returns newly created document when request is valid' do
        do_request pathname: "test.txt", content: "new content"
        new_document = assigns(:document)
        new_document.should be_persisted
        new_document.box.should eq(box)
        new_document.user.should eq(user)
        new_document.pathname.should eq("test.txt")
        new_document.content.should eq("new content")
        response.body.should eq(new_document.to_json)
      end

      context 'with invalid params' do
        it 'does not create new document' do
          expect {
            do_request pathname: "", content: "new content"
          }.to_not change { Document.count }
          response.should_not be_success
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end


  describe 'PUT update' do
    let!(:box) { create :box }
    let!(:document) { create :document, box: box, user: box.owner }

    def do_request(params={})
      put :update, box_id: box.id, id: document.id,
        document: { pathname: 'test.txt', content: 'new content', clean: true },
        format: :json
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when the user is the owner of the document' do
        let!(:user) { box.owner }

        it 'updates the document' do
          expect {
            do_request
          }.to change { document.reload.content }.to('new content')
          response.should be_success
        end

        # this is to prevent content being re-populated in codemirror
        it 'sends only id in the response' do
          do_request
          response.body.should eq({document: {id: document.id}}.to_json)
        end
      end

      context 'when the user is not the owner of the document' do
        let(:user) { create :user }
        before { box.users << user }

        it 'does not update the document' do
          expect {
            do_request
          }.to_not change { document.reload.updated_at }
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'DELETE destroy' do
    let!(:box) { create :box }
    let!(:document) { create :document, box: box, user: box.owner }

    def do_request(params={})
      delete :destroy, box_id: box.id, id: document.id, format: :json
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when the user is the owner of the document' do
        let!(:user) { box.owner }

        it 'deletes the document' do
          do_request
          Document.find_by_id(document.id).should be_nil
          response.should be_success
        end
      end

      context 'when the user is not the owner of the document' do
        let(:user) { create :user }
        before { box.users << user }

        it 'does not delete the document' do
          expect {
            do_request
          }.to_not change { Document.count }
          response.should_not be_success
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
