class Admin::UsersController < AdminController
  layout 'dashboard'
  respond_to :html

  before_filter :find_user, except: [:index]

  def index
    if params[:identifier]
      @user = User.where("email = ? or username = ?", params[:identifier], params[:identifier]).first

      # if no user found by email or username, try with box id
      unless @user
        if box = Box.where(id: params[:identifier]).first
          @user = box.owner
        end
      end
    end
  end

  def edit
    respond_with @user
  end

  def update
    @user.update_attributes params[:user]

    redirect_to admin_users_path(params: { identifier: @user.email })
  end

  def switch
    redirect_to switch_user_path scope_identifier: "user_#{@user.id}"
  end

  def fill_n2o
    respond_with @user
  end

  def commit_fill_n2o
    amount = params[:amount].to_i
    @user.fill_n2o! amount, N2oFill::Kind::FAVOR

    flash[:notice] = "Filled user account with #{amount} of N2O. New N20 level - #{@user.reload.max_n2o}"
    redirect_to admin_users_path(params: { identifier: @user.email })
  end

  private
  def find_user
    @user = User.find params[:id].to_s
  end

end
