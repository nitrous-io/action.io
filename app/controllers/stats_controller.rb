class StatsController < ApplicationController
  before_filter :authenticate_request!

  respond_to :json

  def boxes_count_by_region
    if params[:state]
      respond_with Box.count_by_region(state: params[:state])
    else
      respond_with Box.count_by_region
    end
  end

  def boxes_count_by_template
    respond_with Box.count_by_template
  end

  def boxes_count_by_memory
    respond_with Box.count_by_memory
  end

  def boxes_count_by_storage
    respond_with Box.count_by_storage
  end

  def boxes_running_count
    respond_with Box.running_count
  end

  def boxes_total_count
    respond_with Box.total_count
  end

  def boxes_unterminated_count
    respond_with Box.unterminated_count
  end

  def boxes_born_count
    respond_with Box.born_count
  end

  def boxes_provisioning_count
    respond_with Box.provisioning_count
  end

  def boxes_starting_count
    respond_with Box.starting_count
  end

  def boxes_stopping_count
    respond_with Box.stopping_count
  end

  def boxes_stopped_count
    respond_with Box.stopped_count
  end

  def boxes_terminating_count
    respond_with Box.terminating_count
  end

  def boxes_terminated_count
    respond_with Box.terminated_count
  end

  def boxes_restarting_count
    respond_with Box.restarting_count
  end

  def boxes_reconfiguring_count
    respond_with Box.reconfiguring_count
  end

  def boxes_failed_count
    respond_with Box.failed_count
  end

  def boxes_migrating_count
    respond_with Box.migrating_count
  end

  def users_total_count
    respond_with User.total_count
  end

  protected
  def authenticate_request!
    unless params[:key] == Settings.stats_api_key
      render nothing: true, status: :forbidden
      return
    end
  end
end
