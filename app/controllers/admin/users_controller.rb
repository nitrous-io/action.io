class Admin::UsersController < AdminController
  respond_to :html

  before_filter :find_user, except: [:index]

  def index
    if params[:identifier].present?
      @user = User.where('email = :identifier or username = :identifier', identifier: params[:identifier].downcase).first

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

  def ban
    @user.ban!

    flash[:notice] = "#{@user.username} has been banned."
    redirect_to admin_users_path(params: { identifier: @user.email })
  end

  def switch
    redirect_to switch_user_path scope_identifier: "user_#{@user.id}"
  end

  def fill_n2o
    respond_with @user
  end

  def commit_fill_n2o
    if !EnableN2o
      flash[:notice] = "N2O has been disabled"
      redirect_to admin_users_path(params: { identifier: @user.email })
      return
    end

    amount = params[:amount].to_i
    @user.fill_n2o! amount, N2oFill::Kind::FAVOR

    flash[:notice] = "Filled user account with #{amount} N2O. New N20 level: #{@user.reload.max_n2o}"
    redirect_to admin_users_path(params: { identifier: @user.email })
  end

  def toggle_team_plans
    @user.update_attribute :team_plans_enabled, !@user.team_plans_enabled
    redirect_to admin_users_path(params: { identifier: @user.email })
  end

  private
  def find_user
    @user = User.find params[:id].to_s
  end

end
