class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json, only: :update

  def create
    super

    if resource.persisted?
      IdentifyMixpanelUserJob.submit_job(resource.id, @mixpanel_attributes)
      TrackMixpanelEventJob.submit_job('User Signed Up', resource.id, @mixpanel_attributes)
    end

    if params[:ref].present?
      n2o = KeyValue[N2oFill::N2O_INVITED_SIGNUP_BONUS]
      flash[:info] = "Sign up with this referral code and earn #{n2o} extra units of N2O."
    end
  end

  def confirmation_required
    render layout: 'bootstrap3'
  end

  protected
  def after_update_path_for(resource)
    edit_user_registration_path
  end

  def update
    @user = User.find(current_user.id)
    params[:user].delete(:current_password)
    params[:user].delete(:username)
    @user.update_without_password(params[:user])

    respond_with @user
  end

  def after_inactive_sign_up_path_for(resource)
    users_confirmation_required_url(email: resource.email)
  end
end
