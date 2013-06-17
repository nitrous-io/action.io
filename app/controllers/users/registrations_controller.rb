class Users::RegistrationsController < Devise::RegistrationsController
  before_filter :store_referral_code, only: :new

  def create
    super
    if resource.persisted?
      resource.mark_collaboration_invites_as_accepted!

      if referral_code = session[:referral_code]
        resource.offer_n2o_for_referrals! referral_code
      end

      UserMailer.delay.welcome(resource.email)
      IdentifyMixpanelUserJob.submit_job(user_id: resource.id)
      TrackMixpanelEventJob.submit_job('User Signed Up', resource.id)
    end
  end

  protected
  def after_update_path_for(resource)
    edit_user_registration_path
  end

  def store_referral_code
    session['referral_code'] = params[:ref]
  end

end

