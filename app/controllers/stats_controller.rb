class StatsController < ApplicationController
  before_filter :authenticate_request!

  respond_to :json

  def boxes_count_by_region
    respond_with Box.count_by_region
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
