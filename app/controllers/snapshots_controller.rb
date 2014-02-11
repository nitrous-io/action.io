class SnapshotsController < ApplicationController
  protect_from_forgery

  before_filter :authenticate_user!
  before_filter :find_owned_box, only: [:create]

  respond_to :json

  def index
  end

  def create
    @snapshot = @box.create_snapshot(params[:snapshot])
    TrackMixpanelEventJob.submit_job('Box Snapshot Taken', current_user.id)
    IncrementMixpanelPropertyJob.submit_job(current_user.id, :boxes_snapshotted, 1)
    respond_with @snapshot
  end

  def show
  end

  def update
  end

  def destroy
  end

  protected
  def find_owned_box
    @box = current_user.owned_boxes.find params[:snapshot][:box_id]
  end
end
