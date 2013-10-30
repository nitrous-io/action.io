class Users::RegistrationsController < Devise::RegistrationsController
  def edit
    super
  end

  def create
    super
    if resource.persisted?
      TrackMixpanelEventJob.submit_job('User Signed Up', resource.id)
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

  def after_inactive_sign_up_path_for(resource)
    users_confirmation_required_url(email: resource.email)
  end
end
