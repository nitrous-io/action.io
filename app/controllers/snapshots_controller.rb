class SnapshotsController < ApplicationController
  protect_from_forgery

  before_filter :authenticate_user!
  before_filter :check_if_delinquent_user!, only: [ :create ]
  before_filter :find_owned_box, only: [:create]

  respond_to :json

  def index
    if box = current_user.owned_boxes.find_by_id(params[:box_id])
      @snapshots = box.snapshots.undeleted.chronological_order
    else
      @snapshots = current_user.snapshots.undeleted.chronological_order
    end

    respond_with @snapshots
  end

  def create
    if !@box.snapshottable?
      render json: { errors: { base: ['Box needs to be shut down before a snapshot can be taken.'] } }, status: :unprocessable_entity
      return
    end

    @box.state_triggered_by = current_user
    @snapshot = @box.create_snapshot(params[:snapshot][:name])
    if @snapshot.persisted?
      TrackMixpanelEventJob.submit_job('Box Snapshot Taken', current_user.id,
        template: @box.box_template.try(:name),
        region: @box.region.try(:name)
      )
      IncrementMixpanelPropertyJob.submit_job(current_user.id, :boxes_snapshotted, 1)
    end
    respond_with @snapshot
  end

  def destroy
    @snapshot = current_user.snapshots.find(params[:id])
    @snapshot.enqueue_delete!
    respond_with @snapshot
  end

  protected
  def find_owned_box
    @box = current_user.owned_boxes.find params[:snapshot][:box_id]
  end
end
