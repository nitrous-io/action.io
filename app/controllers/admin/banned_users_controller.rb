class Admin::BannedUsersController < AdminController
  respond_to :html

  def index
    @banned_users = User.banned.order('created_at DESC')
    respond_with :admin, @banned_users
  end
end
