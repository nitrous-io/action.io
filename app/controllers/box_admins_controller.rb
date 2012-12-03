class BoxAdminsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :find_box
  respond_to :html
  layout "dashboard"

  def index
    @users = @box.users
    respond_with @users
  end

  def create
    new_user = User.where(username: params[:user][:username]).first
    if new_user
      @box.add_user new_user
    else
      flash[:error] = 'Username not found'
    end
    redirect_to [@box, :admins]
  end

  def destroy
    if current_user == @box.owner
      user = @box.users.where(username: params[:id]).first
      @box.remove_user user
    end
    redirect_to [@box, :admins]
  end

  protected
  def find_box
    @box = current_user.boxes.find(params[:box_id])
  end
end
