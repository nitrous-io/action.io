class SnapshotsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_box, except: [:index, :create]
  respond_to :json

  def index
    @snapshots = current_user.snapshots
    respond_with @snapshots
  end

  def create
    @snapshot = current_user.create_snapshot(params[:snapshot] || {})
    respond_with @snapshot
  end

  def destroy
    #@box.enqueue_terminate!
    respond_with @snapshot
  end

  protected
  def find_snapshot
    @snapshot = current_user.snapshots.find(params[:id])
  end

end
