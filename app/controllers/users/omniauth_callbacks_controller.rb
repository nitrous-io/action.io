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
    will_sign_in = true
    redirect_to new_user_session_url and return unless omniauth_hash

    if (user = authenticating_user)
      user.update_omniauth_authentication omniauth_hash
      authentication = user.authentications.find_by_provider(@provider)
      if authentication.confirmed?
        flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: provider
        redirect_path = current_user.present? ? edit_user_registration_path : root_path
      else
        will_sign_in = false
        token = omniauth_hash['credentials']['token']
        redirect_path = edit_authentication_path(authentication, token: token )
      end
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

    sign_in user if user.persisted? && will_sign_in
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
      n2o_kinds = {
        'github' => N2oFill::Kind::OAUTH_GITHUB_CONNECT,
        'google' => N2oFill::Kind::OAUTH_GOOGLE_CONNECT,
        'linkedin' => N2oFill::Kind::OAUTH_LINKEDIN_CONNECT
      }
      oauth_action_bonus = KeyValue[N2oFill::N2O_OAUTH_ACTION_BONUS]
      kind = n2o_kinds[@provider]
      current_user.bonus.update_attribute(@provider, Time.now)

      unless current_user.n2o_fills.where(kind: kind).any?
        current_user.fill_n2o! oauth_action_bonus, kind
      end
    end
  end

  def authenticating_user
    current_user || User.find_by_email(omniauth_hash['info']['email'])
  end

  def omniauth_hash
    @omniauth_hash ||= request.env['omniauth.auth']
  end
end
