require 'spec_helper'

describe BoxAdminsController do
  describe 'GET index' do
    let(:user) { create :user }
    let(:another_user) { create :user }
    let(:random_user) { create :user }
    let(:box) { create :box, owner: user, users: [user, another_user] }

    def do_request(box_id=box.id)
      get :index, box_id: box_id
    end

    it 'lists all users of the box' do
      sign_in user
      do_request
      expect(response).to be_success
      expect(assigns(:users)).to eq([user, another_user])
    end

    it_behaves_like 'an action that requires sign in'
  end

  describe 'POST create' do
    let(:user) { create :user }
    let(:another_user) { create :user }
    let(:box1) { create :box, owner: user,         users: [user] }
    let(:box2) { create :box, owner: another_user, users: [another_user] }

    def do_request(params={})
      default = { box_id: box1.to_param, user: { username: another_user.username } }
      post :create, default.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when a valid id is given' do
        context 'when the box belongs to the current user' do
          it 'adds the specified user as box admins' do
            do_request
            expect(box1.reload.users).to include(another_user)
            expect(response).to redirect_to(box_admins_path(box_id: box1.to_param))
          end

          it 'fails when the username does not exist' do
            expect {
              do_request user: { username: 'bs username' }
            }.to_not change { box1.users.count }
            expect(flash[:error]).to eq("Username not found")
            expect(response).to redirect_to(box_admins_path(box_id: box1.to_param))
          end
        end

        context 'when the box belongs to another user' do
          it 'raises record not found' do
            expect {
              do_request box_id: box2.to_param
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end
      end

      context 'when an invalid id is given' do
        it 'raises record not found' do
          expect {
            do_request box_id: 'bs id'
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end

    it_behaves_like 'an action that requires sign in'
  end

  describe 'DELETE destroy' do
    let(:user) { create :user }
    let(:owner) { create :user }
    let(:box) { create :box, owner: owner, users: [owner, user] }

    def do_request(params={})
      default = { box_id: box.to_param, id: user.username }
      delete :destroy, default.merge(params)
    end

    context 'when signed in as owner' do
      before { sign_in owner }

      it 'removes user from the list of admins' do
        Box.any_instance.should_receive(:remove_user).with(user)
        do_request
        expect(response).to redirect_to(box_admins_path(box_id: box.to_param))
      end
    end

    context 'when signed in as collaborator' do
      before { sign_in user }

      it 'does not removes user when current_user is not owner of the box' do
        Box.any_instance.should_not_receive(:remove_user).with(user)
        do_request
        expect(response).to redirect_to(box_admins_path(box_id: box.to_param))
      end
    end

    it_behaves_like 'an action that requires sign in'
  end
end
