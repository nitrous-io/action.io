class BoxhostPlansController < ApplicationController
  before_filter :authenticate_user!
  before_filter :allow_only_dedicated_users
  respond_to :json

  def index
    @boxhost_plans = BoxhostPlan.all
    respond_with @boxhost_plans
  end

  def show
    @boxhost_plan = BoxhostPlan.find(params[:id])
    respond_with @boxhost_plan
  end

  private
  def allow_only_dedicated_users
    unless current_user.dedicated_allowed
      render nothing: true, status: :forbidden
    end
  end
end
