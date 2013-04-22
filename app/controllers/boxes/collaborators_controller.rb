class Boxes::CollaboratorsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_owned_box, except: :remove
  before_filter :find_box, only: :remove

  respond_to :json

  def index
    collaborators = @box.collaborators
    respond_with collaborators
  end

  def add
    collaborator = User.find_by_username! params[:username]

    if @box.users.include? collaborator
      render nothing: true, status: :no_content
      return
    end

    @box.users << collaborator

    Notifier.delay.collaboration_invite(from: current_user.id, to: collaborator.id, box: @box.id)

    TrackMixpanelEventJob.submit_job('Collaborator Added', current_user.id)
    IncrementMixpanelPropertyJob.submit_job(current_user.id, :collaborator_added, 1)
    render json: collaborator.serialize_as_hash(root: 'collaborator'), status: :created
  end

  def remove
    collaborator = User.find_by_username! params[:username]

    if current_user == @box.owner || current_user == collaborator
      box_user = BoxUser.where(box_id: @box.id, user_id: collaborator.id).first

      if box_user.present?
        box_user.destroy
        TrackMixpanelEventJob.submit_job('Collaborator Removed', current_user.id)
        IncrementMixpanelPropertyJob.submit_job(current_user.id, :collaborator_removed, 1)
      end
    end

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
