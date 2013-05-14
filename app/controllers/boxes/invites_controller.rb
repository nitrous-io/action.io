class Boxes::InvitesController < ApplicationController
  before_filter :authenticate_user!
  respond_to :json

  def index
    @box = current_user.owned_boxes.find params[:box_id]
    respond_with @box.collaboration_invites.activated.order("collaboration_invites.id")
  end
end
