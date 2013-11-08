class Boxes::CollaboratorsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_owned_box, except: [:remove, :notify]
  before_filter :find_box, only: [:remove, :notify]

  respond_to :json

  def index
    collaborators = @box.collaborators
    respond_with collaborators
  end

  def create
    status = @box.collaborator_status(params[:identifier])

    if status == Box::ADD_COLLABORATOR
      collaborator = @box.add_collaborator params[:identifier]
      collaborator.add_all_public_keys_to_box(@box.id)

      Notifier.delay.collaboration_invite(from: current_user.id, to: collaborator.id, box: @box.id)
      TrackMixpanelEventJob.submit_job('Collaborator Added', current_user.id)
      IncrementMixpanelPropertyJob.submit_job(current_user.id, :collaborator_added, 1)
      render json: collaborator.serialize_as_hash(root: 'collaborator'), status: :created
    elsif status == Box::COLLABORATOR_EXISTS
      render nothing: true, status: :no_content
    elsif status == Box::INVITE_COLLABORATOR
      invite = @box.invite_collaborator params[:identifier]
      render json: invite.serialize_as_hash(root: 'invite'), status: :created
    elsif status == Box::INVALID_IDENTIFIER
      render nothing: true, status: :no_content
    end
  end

  def remove
    collaborator = User.find_by_username! params[:username]

    if current_user == @box.owner || current_user == collaborator
      box_user = BoxUser.where(box_id: @box.id, user_id: collaborator.id).first

      if box_user.present?
        collaborator.remove_all_public_keys_from_box(@box.id)
        box_user.destroy

        TrackMixpanelEventJob.submit_job('Collaborator Removed', current_user.id)
        IncrementMixpanelPropertyJob.submit_job(current_user.id, :collaborator_removed, 1)
      end
    end

    render nothing: true, status: :no_content
  end

  def notify
    @box.notify_collaborator(params[:username], current_user)
    render nothing: true, status: :no_content
  end

  protected
  def find_owned_box
    @box = current_user.owned_boxes.find params[:box_id]
  end

  def find_box
    @box = current_user.boxes.find params[:box_id]
  end
end
