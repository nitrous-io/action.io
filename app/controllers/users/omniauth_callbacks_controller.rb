class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  after_filter :update_mixpanel, :fill_n2o

  def github
    authenticate_callback 'Github'
  end

  def google_oauth2
    authenticate_callback 'Google'
  end

  def linkedin
    authenticate_callback 'LinkedIn'
  end

  protected
  def authenticate_callback(provider)
    @provider = provider.downcase
    redirect_to new_user_session_url and return unless omniauth_hash

    if (user = authenticating_user)
      user.update_omniauth_authentication omniauth_hash
      flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: provider
      redirect_path = current_user.present? ? edit_user_registration_path : root_path
    else
      user = User.create_from_omniauth_data omniauth_hash
      if user.persisted?
        user.confirm!
        flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: provider
      else
        flash[:notice] = "Cannot create new user. Please try again"
      end
      redirect_path = root_path
    end

    sign_in user if user.persisted?
    redirect_to redirect_path
  end

  def update_mixpanel
    if current_user.present?
      mixpanel_property = :"is_#{@provider}_authenticated"
      SetMixpanelPropertyJob.submit_job(current_user.id, mixpanel_property, true)
    end
  end

  def fill_n2o
    if current_user.present?
      current_user.fill_n2o_for_oauth_action! @provider
    end
  end

  def authenticating_user
    current_user || User.find_by_email(omniauth_hash['info']['email'])
  end

  def omniauth_hash
    @omniauth_hash ||= request.env['omniauth.auth']
  end
end
