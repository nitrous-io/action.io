require 'spec_helper'

describe Boxes::CollaboratorsController do
  let(:user) { create :user }
  let(:collaborator) { create :user }
  let(:collaborator2) { create :user }

  describe 'GET index' do
    let(:box) { create :box, owner: user, users: [user, collaborator, collaborator2] }

    def do_request(params={})
      get :index, { format: 'json', box_id: box.id }.merge(params)
    end

    context 'when signed in' do
      before { sign_in user }

      context 'when a valid box id is given' do
        context 'when the box belongs to the current user' do
          before { do_request }

          it { should respond_with :success }
          its('response.body') { should eq({ collaborators: [collaborator, collaborator2].serialize_as_hash }.to_json) }
        end

        context 'when the box belongs to another user' do
          before do
            box.update_attribute :owner, collaborator
          end

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

  describe 'PUT add' do
    let(:box) { create :box, owner: user, users: [user, collaborator] }

    def do_request(params={})
      put :add, { format: 'json', box_id: box.id, username: collaborator2.username }.merge(params)
    end

    context 'when signed_in' do
      before { sign_in user }

      context 'when a valid box id is given' do
        context 'when the box belongs to the current user' do
          context 'when a user with given username exists' do
            context "when the user has not been added yet" do
              it 'adds the user' do
                expect {
                  do_request
                }.to change { box.collaborators.count }.by(1)

                expect(box.collaborators.reload).to include collaborator2
                expect(controller).to respond_with :no_content
              end
            end

            context 'when the user is already added' do
              before { box.users << collaborator2 }

              it 'does not add the user' do
                expect {
                  do_request
                }.to change { box.collaborators.count }.by(0)

                expect(box.collaborators.reload).to include collaborator2
                expect(controller).to respond_with :no_content
              end
            end
          end

          context 'when a user with given username does not exist' do
            it 'raises record not found' do
              expect {
                do_request box_id: box.id, username: 'random_username'
              }.to raise_error ActiveRecord::RecordNotFound

              expect(box.collaborators.count).to eq 1
            end
          end
        end

        context 'when the box belongs to another user' do
          before do
            box.update_attribute :owner, collaborator
          end

          it 'raises record not found' do
            expect {
              do_request
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end

  describe 'DELETE remove' do
    let(:box) { create :box, owner: user, users: [user, collaborator] }

    def do_request(params={})
      delete :remove, { format: 'json', box_id: box.id, username: collaborator2.username }.merge(params)
    end

    context 'when signed_in' do
      before { sign_in user }

      context 'when a valid box id is given' do
        context 'when the box belongs to the current user' do
          context 'when a user with given username exists' do
            context 'when the user is a user of the box' do
              before { box.users << collaborator2 }

              it 'removes the user' do
                expect {
                  do_request
                }.to change { box.collaborators.count }.by(-1)

                expect(box.collaborators.reload).not_to include collaborator2
                expect(controller).to respond_with :no_content
              end
            end

            context 'when the user is not a user of the box' do
              it 'does not remove the user' do
                expect {
                  do_request
                }.to change { box.collaborators.count }.by(0)

                expect(box.collaborators.reload).not_to include collaborator2
                expect(controller).to respond_with :no_content
              end
            end
          end

          context 'when a user with given username does not exist' do
            it 'raises record not found' do
              expect {
                do_request box_id: box.id, username: 'random_username'
              }.to raise_error ActiveRecord::RecordNotFound

              expect(box.collaborators.count).to eq 1
            end
          end
        end

        context 'when the box belongs to another user' do
          before do
            box.update_attribute :owner, collaborator
          end

          it 'raises record not found' do
            expect {
              do_request
            }.to raise_error ActiveRecord::RecordNotFound
          end
        end
      end
    end

    it_behaves_like 'an action that returns 401 when not signed in'
  end
end
