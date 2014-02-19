class StatsController < ApplicationController
  before_filter :authenticate_request!

  respond_to :json

  def boxes_count_by_group
    group_name = params[:group_name]

    if params[:state]
      respond_with Box.count_by_group(group_name, state: params[:state])
    else
      respond_with Box.count_by_group(group_name)
    end
  end

  def boxes_count
    respond_with Box.count_by(state: params[:state], region_name: params[:region_name])
  end

  def users_count
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
