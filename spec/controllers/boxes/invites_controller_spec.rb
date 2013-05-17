require 'spec_helper'

describe Boxes::InvitesController do
  describe 'GET index' do
    let!(:user)   { create :user }
    let!(:box)    { create :box, owner: user }
    let!(:ci_1)   { create :collaboration_invite, box: box, state: 'accepted' }
    let!(:ci_2)   { create :collaboration_invite, box: box }

    def do_request(params={})
      get :index, { format: 'json', box_id: box.id }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when a valid box id is given' do
        context 'when the box belongs to the current user' do
          it 'returns activated invites' do
            do_request
            response.should be_success
            response.body.should eq({invites: [ci_2].serialize_as_hash}.to_json)
          end
        end

        context 'when the box belongs to another user' do
          let!(:another_user) { create :user }
          before { box.update_attribute :owner, another_user }

          it 'raises record not found' do
            expect {
              do_request
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end
      end

      context 'when an invalid box id is given' do
        it 'raises record not found' do
          expect {
            do_request box_id: 'bs id'
          }.to raise_error ActiveRecord::RecordNotFound
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
