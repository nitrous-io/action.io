class Admin::UsersController < AdminController
  layout 'dashboard'

  def switch_user
    if user = User.where(email: params[:email]).first
      redirect_to switch_user_path scope_identifier: "user_#{user.id}"
    else
      flash[:notice] = 'Invalid user email. Please try again!!'
      redirect_to admin_users_path
    end
  end
end
