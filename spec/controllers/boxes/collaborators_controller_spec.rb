require 'spec_helper'

describe Boxes::CollaboratorsController do
  let(:user)          { create :user }
  let(:collaborator)  { create :user }
  let(:collaborator2) { create :user }
  let(:another_user)  { create :user }

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

  describe 'POST create' do
    let(:box) { create :box, owner: user, users: [user, collaborator] }

    def do_request(params={})
      post :create, { format: 'json', box_id: box.id, identifier: collaborator2.username }.merge(params)
    end

    context 'when signed_in' do
      before { sign_in user }

      context 'when a valid box id is given' do
        context 'when the box belongs to the current user' do
          context 'when a user with given username exists' do
            context "when the user has not been added yet" do
              it 'adds the user' do
                IncrementMixpanelPropertyJob.should_receive(:submit_job).with(user.id, :collaborator_added, 1)
                TrackMixpanelEventJob.should_receive(:submit_job).with('Collaborator Added', user.id)

                expect {
                  do_request
                }.to change { box.collaborators.count }.by(1)

                expect(box.collaborators.reload).to include collaborator2
                expect(controller).to respond_with :created
                expect(response.body).to eq(collaborator2.serialize_as_json root: 'collaborator')
              end

              it 'sends an email to the user with the collaboration invite' do
                TrackMixpanelEventJob.stub!(:submit_job)
                IncrementMixpanelPropertyJob.stub!(:submit_job)

                expect {
                  do_request
                }.to change { Delayed::Job.count }.by(1)

                Delayed::Job.first.handler.should match(/collaboration_invite/)
              end
            end

            context 'when the user is already added' do
              before { box.users << collaborator2 }

              it 'does not add the user' do
                IncrementMixpanelPropertyJob.should_not_receive(:submit_job).with(user.id, :collaborator_added, 1)
                TrackMixpanelEventJob.should_not_receive(:submit_job).with('Collaborator Added', user.id)

                expect {
                  do_request
                }.to change { box.collaborators.count }.by(0)

                expect(box.collaborators.reload).to include collaborator2
                expect(controller).to respond_with :no_content
              end
            end
          end

          context 'when a user with given email does not exist' do
            it 'sends an invite to the user' do
              expect {
                do_request box_id: box.id, identifier: 'random@email.com'
              }.to change { box.collaboration_invites.count }.by 1

              expect(response.body).to eq(CollaborationInvite.last.serialize_as_json root: 'invite')
            end
          end
        end

        context 'when the box belongs to another user' do
          before do
            box.update_attribute :owner, collaborator
          end

          it 'raises record not found' do
            IncrementMixpanelPropertyJob.should_not_receive(:submit_job).with(user.id, :collaborator_added, 1)
            TrackMixpanelEventJob.should_not_receive(:submit_job).with('Collaborator Added', user.id)

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
    let(:another_box) { create :box, owner: another_user, users: [user, another_user, collaborator] }

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
                IncrementMixpanelPropertyJob.should_receive(:submit_job).with(user.id, :collaborator_removed, 1)
                TrackMixpanelEventJob.should_receive(:submit_job).with('Collaborator Removed', user.id)

                expect {
                  do_request
                }.to change { box.collaborators.count }.by(-1)

                expect(box.collaborators.reload).not_to include collaborator2
                expect(controller).to respond_with :no_content
              end
            end

            context 'when the user is not a user of the box' do
              it 'does not remove the user' do
                IncrementMixpanelPropertyJob.should_not_receive(:submit_job).with(user.id, :collaborator_removed, 1)
                TrackMixpanelEventJob.should_not_receive(:submit_job).with('Collaborator Removed', user.id)

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
              IncrementMixpanelPropertyJob.should_not_receive(:submit_job).with(user.id, :collaborator_removed, 1)
              TrackMixpanelEventJob.should_not_receive(:submit_job).with('Collaborator Removed', user.id)

              expect {
                do_request box_id: box.id, username: 'random_username'
              }.to raise_error ActiveRecord::RecordNotFound

              expect(box.collaborators.count).to eq 1
            end
          end
        end

        context 'when the current user is a collaborator' do
          context 'when he tries to remove himself' do
            it 'removes the user' do
              IncrementMixpanelPropertyJob.should_receive(:submit_job).with(user.id, :collaborator_removed, 1)
              TrackMixpanelEventJob.should_receive(:submit_job).with('Collaborator Removed', user.id)

              expect {
                do_request box_id: another_box.id, username: user.username
              }.to change { another_box.collaborators.count }.by(-1)

              expect(another_box.collaborators.reload).not_to include user
              expect(controller).to respond_with :no_content
            end
          end

          context 'when he tries to remove another collaborator' do
            it 'does not remove the user' do
              IncrementMixpanelPropertyJob.should_not_receive(:submit_job)
              TrackMixpanelEventJob.should_not_receive(:submit_job)

              expect {
                do_request box_id: another_box.id, username: collaborator.username
              }.to change { box.collaborators.count }.by(0)

              expect(box.collaborators.reload).to include collaborator
              expect(controller).to respond_with :no_content
            end
          end
        end

        context 'when the current user is not a owner or a collaborator of the box' do
          before do
            box.update_attribute :owner, another_user
            box.users = [ another_user, collaborator ]
            box.save
          end

          it 'raises record not found' do
            IncrementMixpanelPropertyJob.should_not_receive(:submit_job).with(user.id, :collaborator_removed, 1)
            TrackMixpanelEventJob.should_not_receive(:submit_job).with('Collaborator Removed', user.id)

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
