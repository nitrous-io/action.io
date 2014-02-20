class StatsController < ApplicationController
  before_filter :authenticate_request!

  respond_to :json

  def boxes_count_by_group
    group_name = params.delete :group_name

    %w(action controller format key).each { |k| params.delete k }

    respond_with Box.count_by_group(group_name, params)
  end

  def boxes_count
    respond_with Box.count_by(params)
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
