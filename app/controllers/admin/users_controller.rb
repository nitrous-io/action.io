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
    # :bypass option avoids warden callbacks such as Devise::Trackable hooks
    # which set last_sign_in_at
    sign_out && sign_in(:user, @user, bypass: true)

    redirect_to root_path
  end

  def fill_n2o
    respond_with @user
  end

  def commit_fill_n2o
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
