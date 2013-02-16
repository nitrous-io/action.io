class SnapshotsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_box
  respond_to :json

  def index
    @snapshots = current_user.snapshots
    respond_with @snapshots
  end

  def create
    snapshot_params = params[:snapshot] || {}
    box = current_user.boxes.find(snapshot_params[:box_id])
    @snapshot = box.snapshot(snapshot_params)
    respond_with @snapshot
  end

  private
  def find_box
    box = current_user.boxes.find(params[:box_id])
  end
end
