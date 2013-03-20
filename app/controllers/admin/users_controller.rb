class Admin::UsersController < AdminController
  layout 'dashboard'

  def switch_user
    if user = User.where("email = ? or username = ?", params[:identifier], params[:identifier]).first
      redirect_to switch_user_path scope_identifier: "user_#{user.id}"
    elsif box = Box.where(id: params[:identifier]).first
      user = box.owner
      redirect_to switch_user_path scope_identifier: "user_#{user.id}"
    else
      flash[:notice] = 'Invalid user identifier. Please enter a valid email, username or a box id!!'
      redirect_to admin_users_path
    end
  end
end
