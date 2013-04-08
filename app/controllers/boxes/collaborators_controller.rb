class Boxes::CollaboratorsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_box

  respond_to :json

  def index
    collaborators = @box.collaborators
    respond_with collaborators
  end

  def add
    collaborator = User.find_by_username! params[:username]
    @box.users << collaborator unless @box.users.include? collaborator
    render nothing: true, status: :no_content
  end

  def remove
    collaborator = User.find_by_username! params[:username]
    BoxUser.where(box_id: @box.id, user_id: collaborator.id).first.try(:destroy)
    render nothing: true, status: :no_content
  end

  protected
  def find_box
    @box = current_user.owned_boxes.find params[:box_id]
  end
end
