class Users::RegistrationsController < Devise::RegistrationsController
  def edit
    super
  end

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

  protected
  def after_update_path_for(resource)
    edit_user_registration_path
  end
end

