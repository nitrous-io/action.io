class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json, only: :update

  def create
    super

    if resource.persisted?
      IdentifyMixpanelUserJob.submit_job(user_id: resource.id)
      TrackMixpanelEventJob.submit_job('User Signed Up', resource.id)
    end

    if params[:ref].present?
      n2o = KeyValue[N2oFill::N2O_INVITED_SIGNUP_BONUS]
      flash[:info] = "Sign up with this referral code and earn #{n2o} extra units of N2O."
    end
  end

  def update
    @user = User.find(current_user.id)
    params[:user].delete(:current_password)
    params[:user].delete(:username)
    @user.update_without_password(params[:user])

    respond_with @user
  end

end

