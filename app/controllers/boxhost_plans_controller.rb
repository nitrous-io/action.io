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

  def subscribe
    @boxhost_plan = BoxhostPlan.find(params[:id])

    boxhost = Boxhost.new
    boxhost.boxhost_plan = @boxhost_plan
    boxhost.owner = current_user
    boxhost.name = boxhost.generate_name
    boxhost.save!

    render nothing: true, status: :created
  end
end
