class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  after_filter :update_mixpanel

  def github
    @provider = 'github'
    redirect_to new_user_session_url and return unless omniauth_hash

    if (user = authenticating_user)
      user.update_github_authentication omniauth_hash
      flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: 'GitHub'
      redirect_path = current_user.present? ? edit_user_registration_path : root_path
    else
      user = User.create_from_github_data(omniauth_hash)
      if user.persisted?
        flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: 'GitHub'
      else
        flash[:notice] = "Cannot create new user. Please try again"
      end
      redirect_path = root_path
    end

    sign_in user if user.persisted?
    redirect_to redirect_path
  end

  protected
  def update_mixpanel
    if current_user.present?
      mixpanel_property = :"is_#{@provider}_authenticated"
      SetMixpanelPropertyJob.submit_job(current_user.id, mixpanel_property, true)
    end
  end

  def authenticating_user
    current_user || User.find_by_email(omniauth_hash['info']['email'])
  end

  def omniauth_hash
    @omniauth_hash ||= request.env['omniauth.auth']
  end
end
