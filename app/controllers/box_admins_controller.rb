class BoxAdminsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_box
  respond_to :html, :json
  layout "dashboard"

  def index
    @users = @box.users
    respond_with @users
  end

  def create
    new_user = User.where(username: params[:user][:username]).first
    if new_user
      @box_admins = @box.add_user new_user
      respond_to do |format|
        format.html { redirect_to [@box, :admins] }
        format.json { render json: @box_admins }
      end
    else
      respond_to do |format|
        format.html do
          flash[:error] = 'Username not found'
          redirect_to [@box, :admins]
        end
        format.json do
          render json: { status: "error", message: 'Username not found' }, status: 404
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      if current_user == @box.owner
        user = @box.users.where(username: params[:id]).first
        @box.remove_user user
        format.json { head :ok }
      else
        format.json { head :forbidden }
      end
      format.html { redirect_to [@box, :admins] }
    end
  end

  protected
  def find_box
    @box = current_user.boxes.find(params[:box_id])
  end
end
